import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/models/app_user_profile.dart' as admin_models;
import '../core/models/mobile_models.dart';
import '../core/services/auth_service.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_customer_page.dart';
import '../features/auth/register_technician_page.dart';
import '../features/admin/admin_shell.dart';
import '../features/customer/customer_shell_page.dart';
import '../features/guest/home_page.dart';
import '../features/technician/technician_shell_page.dart';
import 'theme.dart';

class SiTeknisiApp extends StatelessWidget {
  const SiTeknisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Si Teknisi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.registerCustomer: (_) => const RegisterCustomerPage(),
        AppRoutes.registerTechnician: (_) => const RegisterTechnicianPage(),
      },
      home: AppConfig.hasSupabaseConfig
          ? AuthGate(authService: AuthService(Supabase.instance.client))
          : const MissingSupabaseConfigPage(),
    );
  }
}

class AppRoutes {
  const AppRoutes._();

  static const login = '/login';
  static const registerCustomer = '/register/customer';
  static const registerTechnician = '/register/technician';
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.authService, super.key});

  final AuthService authService;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<AppProfile?> _profileFuture = widget.authService.currentProfile();
  String? _profileUserId;

  void _reloadProfile() {
    setState(() {
      _profileUserId = widget.authService.currentUser?.id;
      _profileFuture = widget.authService.currentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: widget.authService.authChanges,
      builder: (context, snapshot) {
        final session = widget.authService.currentSession;
        if (session == null) {
          _profileUserId = null;
          return const GuestHomePage();
        }
        if (_profileUserId != session.user.id) {
          _profileUserId = session.user.id;
          _profileFuture = widget.authService.currentProfile();
        }
        return FutureBuilder<AppProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SplashLoadingPage();
            }
            final profile = snapshot.data;
            if (profile == null) {
              return _ProfileErrorPage(onRetry: _reloadProfile);
            }
            if (!profile.isActive) {
              return _InactiveAccountPage(authService: widget.authService);
            }
            return switch (profile.role) {
              AppRole.technician => TechnicianShellPage(
                profile: profile,
                authService: widget.authService,
              ),
              AppRole.admin => AdminShell(
                profile: admin_models.AppUserProfile(
                  id: profile.id,
                  email: profile.email,
                  fullName: profile.fullName,
                  role: admin_models.AppRole.admin,
                  isActive: profile.isActive,
                ),
                authService: widget.authService,
              ),
              AppRole.customer => CustomerShellPage(
                profile: profile,
                authService: widget.authService,
              ),
            };
          },
        );
      },
    );
  }
}

class MissingSupabaseConfigPage extends StatelessWidget {
  const MissingSupabaseConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Konfigurasi Supabase belum tersedia. Isi SUPABASE_URL dan SUPABASE_ANON_KEY lalu jalankan ulang aplikasi.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _SplashLoadingPage extends StatelessWidget {
  const _SplashLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Muat ulang profil'),
        ),
      ),
    );
  }
}

class _InactiveAccountPage extends StatelessWidget {
  const _InactiveAccountPage({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton.icon(
          onPressed: authService.signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Akun nonaktif, keluar'),
        ),
      ),
    );
  }
}
