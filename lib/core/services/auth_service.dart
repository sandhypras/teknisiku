import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mobile_models.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> registerCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'customer', 'full_name': fullName, 'phone': phone},
    );
  }

  Future<void> registerTechnician({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'role': 'technician', 'full_name': fullName, 'phone': phone},
    );
  }

  Future<AppProfile?> currentProfile() async {
    final id = currentUser?.id;
    if (id == null) return null;
    final row = await _client
        .from('profiles')
        .select('id, email, full_name, phone, role, is_active')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : AppProfile.fromJson(row);
  }

  Future<void> signOut() => _client.auth.signOut();
}
