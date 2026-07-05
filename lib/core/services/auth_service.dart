import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_profile.dart' as admin_models;
import '../models/mobile_models.dart' as mobile_models;

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  Future<void> resendSignupOtp({required String email}) async {
    await _client.auth.resend(email: email, type: OtpType.signup);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'siteknisi://reset-password',
    );
  }

  Future<bool?> isEmailRegistered({required String email}) async {
    try {
      final result = await _client.rpc<bool>(
        'email_exists',
        params: {'lookup_email': email.trim()},
      );
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePassword({required String password}) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  Future<AuthResponse> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'customer',
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<AuthResponse> registerTechnician({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'technician',
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<mobile_models.AppProfile?> currentProfile() async {
    final id = currentUser?.id;
    if (id == null) return null;
    final row = await _client
        .from('profiles')
        .select(
          'id, email, full_name, phone, role, is_active, profile_image_url',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return mobile_models.AppProfile.fromJson({
      ...row,
      'profile_image_url': _publicProfileImageUrl(
        row['profile_image_url'] as String?,
      ),
    });
  }

  Future<admin_models.AppUserProfile?> getCurrentProfile() async {
    final id = currentUser?.id;
    if (id == null) return null;
    final row = await _client
        .from('profiles')
        .select('id, email, full_name, role, is_active')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : admin_models.AppUserProfile.fromJson(row);
  }

  Future<void> signOut() => _client.auth.signOut();
}

String? _publicProfileImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final value = path.trim();
  if (value.startsWith('http')) return value;
  final objectPath = value.startsWith('profile-images/')
      ? value.substring('profile-images/'.length)
      : value;
  if (objectPath.isEmpty) return null;
  return Supabase.instance.client.storage
      .from('profile-images')
      .getPublicUrl(objectPath);
}
