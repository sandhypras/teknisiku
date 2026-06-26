import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';
import 'technician_dashboard_page.dart';
import 'technician_orders_page.dart';
import 'technician_profile_page.dart';
import 'technician_services_page.dart';

class TechnicianShellPage extends StatefulWidget {
  const TechnicianShellPage({
    required this.profile,
    required this.authService,
    super.key,
  });

  final AppProfile profile;
  final AuthService authService;

  @override
  State<TechnicianShellPage> createState() => _TechnicianShellPageState();
}

class _TechnicianShellPageState extends State<TechnicianShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final repo = MarketplaceRepository(Supabase.instance.client);
    final pages = [
      TechnicianDashboardPage(profile: widget.profile, repo: repo),
      TechnicianOrdersPage(repo: repo),
      TechnicianServicesPage(repo: repo),
      TechnicianProfilePage(
        profile: widget.profile,
        repo: repo,
        authService: widget.authService,
      ),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: AppColors.secondary.withValues(alpha: 0.14),
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline_rounded),
            selectedIcon: Icon(Icons.work_rounded),
            label: 'Order Saya',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Pesan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}

class TechnicianHeader extends StatelessWidget {
  const TechnicianHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
