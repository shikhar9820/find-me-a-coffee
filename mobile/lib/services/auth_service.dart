import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _client => SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Send OTP to phone number
  Future<void> sendOtp(String phoneNumber) async {
    // Ensure phone number is in correct format (+91...)
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    await _client.auth.signInWithOtp(
      phone: formattedPhone,
    );
  }

  /// Verify OTP and sign in
  Future<AppUser?> verifyOtp(String phoneNumber, String otp) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    final response = await _client.auth.verifyOTP(
      phone: formattedPhone,
      token: otp,
      type: OtpType.sms,
    );

    if (response.user != null) {
      // Check if user profile exists, create if not
      return await _ensureUserProfile(response.user!);
    }

    return null;
  }

  /// Get or create user profile in our users table
  Future<AppUser?> _ensureUserProfile(User authUser) async {
    // Try to get existing profile
    final existing = await _client
        .from('users')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (existing != null) {
      return AppUser.fromJson(existing);
    }

    // Create new profile
    final newUser = {
      'id': authUser.id,
      'phone': authUser.phone,
      'created_at': DateTime.now().toIso8601String(),
    };

    final result = await _client.from('users').insert(newUser).select().single();

    return AppUser.fromJson(result);
  }

  /// Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    if (currentUser == null) return null;

    final result = await _client
        .from('users')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();

    if (result == null) return null;
    return AppUser.fromJson(result);
  }

  /// Update user profile
  Future<AppUser?> updateProfile({String? name, String? email}) async {
    if (currentUser == null) return null;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (email != null) updates['email'] = email;

    if (updates.isEmpty) return getCurrentUserProfile();

    final result = await _client
        .from('users')
        .update(updates)
        .eq('id', currentUser!.id)
        .select()
        .single();

    return AppUser.fromJson(result);
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Format phone number to E.164 format
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    var digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // If it starts with 0, remove it
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // If it's a 10-digit Indian number, add +91
    if (digits.length == 10) {
      return '+91$digits';
    }

    // If it already has country code (12 digits starting with 91)
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }

    // Return as-is with + if not already present
    return phone.startsWith('+') ? phone : '+$digits';
  }
}
