import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/cafe.dart';
import '../models/stamp.dart';
import '../models/redemption.dart';

class StampResult {
  final bool success;
  final StampSummary? summary;
  final String? error;
  final bool isNewCafe;

  StampResult.success(this.summary, {this.isNewCafe = false})
      : success = true,
        error = null;

  StampResult.failure(this.error)
      : success = false,
        summary = null,
        isNewCafe = false;
}

class StampService {
  static final StampService _instance = StampService._internal();
  factory StampService() => _instance;
  StampService._internal();

  SupabaseClient get _client => SupabaseConfig.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Collect a stamp at a cafe
  /// Rate limited: 1 stamp per cafe per 30 minutes
  Future<StampResult> collectStamp(String cafeId) async {
    if (_userId == null) {
      return StampResult.failure('Not logged in');
    }

    try {
      // Check if cafe exists and is active
      final cafe = await _client
          .from('cafes')
          .select()
          .eq('id', cafeId)
          .eq('is_active', true)
          .maybeSingle();

      if (cafe == null) {
        return StampResult.failure('Cafe not found or inactive');
      }

      // Check rate limit (1 stamp per 30 min per cafe)
      final thirtyMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 30));

      final recentStamp = await _client
          .from('stamps')
          .select()
          .eq('user_id', _userId!)
          .eq('cafe_id', cafeId)
          .gte('stamped_at', thirtyMinutesAgo.toIso8601String())
          .maybeSingle();

      if (recentStamp != null) {
        return StampResult.failure(
            'You already collected a stamp here recently. Try again in 30 minutes.');
      }

      // Check if this is user's first stamp at this cafe
      final existingStampCount = await _client
          .from('stamps')
          .select()
          .eq('user_id', _userId!)
          .eq('cafe_id', cafeId)
          .count(CountOption.exact);

      final isNewCafe = (existingStampCount.count ?? 0) == 0;

      // Add the stamp
      await _client.from('stamps').insert({
        'user_id': _userId,
        'cafe_id': cafeId,
        'stamped_at': DateTime.now().toIso8601String(),
      });

      // Get updated summary
      final summary = await getStampSummaryForCafe(cafeId);

      return StampResult.success(summary, isNewCafe: isNewCafe);
    } catch (e) {
      return StampResult.failure('Failed to collect stamp: $e');
    }
  }

  /// Get stamp summary for a specific cafe
  Future<StampSummary?> getStampSummaryForCafe(String cafeId) async {
    if (_userId == null) return null;

    final result = await _client.rpc('get_stamp_summary_for_cafe', params: {
      'p_user_id': _userId,
      'p_cafe_id': cafeId,
    }).maybeSingle();

    if (result == null) return null;
    return StampSummary.fromJson(result);
  }

  /// Get all stamp summaries for current user (cafes they have stamps at)
  Future<List<StampSummary>> getUserStampSummaries() async {
    if (_userId == null) return [];

    final results = await _client.rpc('get_user_stamp_summaries', params: {
      'p_user_id': _userId,
    });

    return (results as List)
        .map((json) => StampSummary.fromJson(json))
        .toList();
  }

  /// Create a redemption (when user wants to claim reward)
  Future<Redemption?> createRedemption(String cafeId) async {
    if (_userId == null) return null;

    try {
      // Get cafe details
      final cafe = await _client
          .from('cafes')
          .select()
          .eq('id', cafeId)
          .single();

      // Count user's stamps at this cafe
      final stampCount = await _client
          .from('stamps')
          .select()
          .eq('user_id', _userId!)
          .eq('cafe_id', cafeId)
          .count(CountOption.exact);

      final stampsRequired = cafe['stamps_required'] as int;

      if ((stampCount.count ?? 0) < stampsRequired) {
        return null; // Not enough stamps
      }

      // Generate redemption code
      final code = _generateRedemptionCode();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 15));

      // Create redemption
      final result = await _client.from('redemptions').insert({
        'user_id': _userId,
        'cafe_id': cafeId,
        'stamps_used': stampsRequired,
        'reward_description': cafe['reward_description'] ?? 'Free coffee',
        'redemption_code': code,
        'is_claimed': false,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      }).select().single();

      // Delete used stamps (oldest first)
      final stampsToDelete = await _client
          .from('stamps')
          .select('id')
          .eq('user_id', _userId!)
          .eq('cafe_id', cafeId)
          .order('stamped_at', ascending: true)
          .limit(stampsRequired);

      final stampIds = (stampsToDelete as List).map((s) => s['id']).toList();

      await _client.from('stamps').delete().inFilter('id', stampIds);

      return Redemption.fromJson(result);
    } catch (e) {
      print('Error creating redemption: $e');
      return null;
    }
  }

  /// Get user's redemption history
  Future<List<Redemption>> getRedemptionHistory() async {
    if (_userId == null) return [];

    final results = await _client
        .from('redemptions')
        .select('''
          *,
          cafes (
            name,
            logo_url
          )
        ''')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (results as List).map((json) {
      final cafe = json['cafes'];
      return Redemption.fromJson({
        ...json,
        'cafe_name': cafe?['name'],
        'cafe_logo_url': cafe?['logo_url'],
      });
    }).toList();
  }

  /// Get active (unclaimed, unexpired) redemptions
  Future<List<Redemption>> getActiveRedemptions() async {
    if (_userId == null) return [];

    final now = DateTime.now().toIso8601String();

    final results = await _client
        .from('redemptions')
        .select('''
          *,
          cafes (
            name,
            logo_url
          )
        ''')
        .eq('user_id', _userId!)
        .eq('is_claimed', false)
        .gte('expires_at', now)
        .order('expires_at', ascending: true);

    return (results as List).map((json) {
      final cafe = json['cafes'];
      return Redemption.fromJson({
        ...json,
        'cafe_name': cafe?['name'],
        'cafe_logo_url': cafe?['logo_url'],
      });
    }).toList();
  }

  /// Generate a short redemption code
  String _generateRedemptionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = random;

    for (var i = 0; i < 6; i++) {
      code += chars[seed % chars.length];
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    }

    return code;
  }
}
