import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/app_user_profile.dart';
import '../../core/services/auth_service.dart';
import '../admin/data/admin_dashboard_service.dart';
import '../admin/presentation/admin_dashboard_screen.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    required this.profile,
    required this.authService,
    super.key,
  });

  final AppUserProfile profile;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    if (profile.role == AppRole.admin) {
      return AdminDashboardScreen(
        profile: profile,
        authService: authService,
        dashboardService: AdminDashboardService(Supabase.instance.client),
      );
    }

    final title = switch (profile.role) {
      AppRole.customer => 'Home Customer',
      AppRole.technician => 'Dashboard Teknisi',
      AppRole.admin => 'Dashboard Admin',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halo, ${profile.fullName.isEmpty ? profile.email : profile.fullName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Role: ${profile.role.label}'),
            ],
          ),
        ),
      ),
    );
  }
}
