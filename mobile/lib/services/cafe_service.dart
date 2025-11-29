import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/cafe.dart';

class CafeService {
  static final CafeService _instance = CafeService._internal();
  factory CafeService() => _instance;
  CafeService._internal();

  SupabaseClient get _client => SupabaseConfig.client;
  String? get _userId => _client.auth.currentUser?.id;

  /// Get cafe by ID
  Future<Cafe?> getCafeById(String cafeId) async {
    final result = await _client
        .from('cafes')
        .select()
        .eq('id', cafeId)
        .eq('is_active', true)
        .maybeSingle();

    if (result == null) return null;
    return Cafe.fromJson(result);
  }

  /// Get cafe by NFC tag ID
  Future<Cafe?> getCafeByNfcTag(String nfcTagId) async {
    final result = await _client
        .from('cafes')
        .select()
        .eq('nfc_tag_id', nfcTagId)
        .eq('is_active', true)
        .maybeSingle();

    if (result == null) return null;
    return Cafe.fromJson(result);
  }

  /// Get nearby cafes
  Future<List<Cafe>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 50,
  }) async {
    // Using PostGIS function for distance calculation
    final results = await _client.rpc('get_nearby_cafes', params: {
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_radius_km': radiusKm,
      'p_limit': limit,
    });

    return (results as List).map((json) => Cafe.fromJson(json)).toList();
  }

  /// Get cafes in a city
  Future<List<Cafe>> getCafesByCity(String city) async {
    final results = await _client
        .from('cafes')
        .select()
        .eq('city', city)
        .eq('is_active', true)
        .order('name');

    return (results as List).map((json) => Cafe.fromJson(json)).toList();
  }

  /// Search cafes by name
  Future<List<Cafe>> searchCafes(String query) async {
    final results = await _client
        .from('cafes')
        .select()
        .eq('is_active', true)
        .ilike('name', '%$query%')
        .limit(20);

    return (results as List).map((json) => Cafe.fromJson(json)).toList();
  }

  /// Get cafes where user has stamps
  Future<List<Cafe>> getCafesWithUserStamps() async {
    if (_userId == null) return [];

    final results = await _client.rpc('get_cafes_with_user_stamps', params: {
      'p_user_id': _userId,
    });

    return (results as List).map((json) => Cafe.fromJson(json)).toList();
  }

  /// Get featured/popular cafes
  Future<List<Cafe>> getFeaturedCafes({int limit = 10}) async {
    // For now, just get recently active cafes
    // Later can add more sophisticated ranking
    final results = await _client
        .from('cafes')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return (results as List).map((json) => Cafe.fromJson(json)).toList();
  }
}
