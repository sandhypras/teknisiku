import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/auth_service.dart';
import '../../shared/mobile_ui.dart';
import 'customer_shell_page.dart';

class CustomerProfilePage extends StatelessWidget {
  const CustomerProfilePage({
    required this.profile,
    required this.authService,
    super.key,
  });

  final AppProfile profile;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const CustomerAppBar(
            title: 'Profil',
            subtitle: 'Data akun dari tabel profiles',
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.secondary.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      profile.fullName.isEmpty
                          ? 'C'
                          : profile.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  StatusPill(
                    label: profile.role.label,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: authService.signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
