import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/app_user_profile.dart';
import '../../core/services/auth_service.dart';
import '../home/role_home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.authService, super.key});

  final AuthService authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<AppUserProfile?> _profileFuture;
  String? _profileUserId;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.authService.getCurrentProfile();
  }

  void _reloadProfile() {
    setState(() {
      _profileUserId = widget.authService.currentUser?.id;
      _profileFuture = widget.authService.getCurrentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: widget.authService.authStateChanges,
      builder: (context, snapshot) {
        final session = widget.authService.currentSession;

        if (session == null) {
          _profileUserId = null;
          return LoginScreen(authService: widget.authService);
        }

        if (_profileUserId != session.user.id) {
          _profileUserId = session.user.id;
          _profileFuture = widget.authService.getCurrentProfile();
        }

        return FutureBuilder<AppUserProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final profile = snapshot.data;
            if (profile == null) {
              return _ProfileErrorScreen(onRetry: _reloadProfile);
            }

            if (!profile.isActive) {
              return _InactiveAccountScreen(authService: widget.authService);
            }

            return RoleHomeScreen(
              profile: profile,
              authService: widget.authService,
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileErrorScreen extends StatelessWidget {
  const _ProfileErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Center(
        child: FilledButton(
          onPressed: onRetry,
          child: const Text('Muat ulang profil'),
        ),
      ),
    );
  }
}

class _InactiveAccountScreen extends StatelessWidget {
  const _InactiveAccountScreen({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Akun nonaktif')),
      body: Center(
        child: FilledButton(
          onPressed: authService.signOut,
          child: const Text('Keluar'),
        ),
      ),
    );
  }
}
