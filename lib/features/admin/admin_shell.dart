import 'package:flutter/material.dart';

import '../../core/models/app_user_profile.dart';
import '../../core/services/auth_service.dart';
import 'customers/admin_customers_screen.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'services/admin_services_screen.dart';
import 'technicians/admin_technicians_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    required this.profile,
    required this.authService,
    super.key,
  });

  final AppUserProfile profile;
  final AuthService authService;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.verified_user_rounded, label: 'Teknisi'),
    _NavItem(icon: Icons.build_circle_rounded, label: 'Layanan'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Pesanan'),
    _NavItem(icon: Icons.people_alt_rounded, label: 'Customer'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 800;

    final screens = [
      const AdminDashboardScreen(),
      const AdminTechniciansScreen(),
      const AdminServicesScreen(),
      const AdminOrdersScreen(),
      const AdminCustomersScreen(),
    ];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(
              items: _navItems,
              selectedIndex: _selectedIndex,
              profile: widget.profile,
              onSelect: (i) => setState(() => _selectedIndex = i),
              onSignOut: widget.authService.signOut,
            ),
            Expanded(child: screens[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: widget.authService.signOut,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _navItems
            .map((e) => NavigationDestination(icon: Icon(e.icon), label: e.label))
            .toList(),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.profile,
    required this.onSelect,
    required this.onSignOut,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final AppUserProfile profile;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  'Si Teknisi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final selected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    selected: selected,
                    selectedTileColor: Colors.white.withValues(alpha: 0.15),
                    leading: Icon(items[i].icon,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                        size: 20),
                    title: Text(
                      items[i].label,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => onSelect(i),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName.isEmpty ? 'Admin' : profile.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile.email,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white70, size: 20),
                  tooltip: 'Keluar',
                  onPressed: onSignOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

abstract class AppColors {
  static const primary = Color(0xFF16324F);
  static const teal = Color(0xFF00A6A6);
  static const amber = Color(0xFFF4A261);
  static const background = Color(0xFFF6F8FA);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
}

// --------------- Shared admin widgets ---------------

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
