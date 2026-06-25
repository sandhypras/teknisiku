import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user_profile.dart';

class AuthService {
  AuthService(this._supabase);

  final SupabaseClient _supabase;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) {
    return _supabase.auth.signUp(
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
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'technician',
        'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<void> signOut() {
    return _supabase.auth.signOut();
  }

  Future<AppUserProfile?> getCurrentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) {
      return null;
    }

    final row = await _supabase
        .from('profiles')
        .select('id, email, full_name, role, is_active')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return AppUserProfile.fromJson(row);
  }
}
