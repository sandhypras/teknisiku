import 'package:flutter/material.dart';

import '../../core/models/app_user_profile.dart';
import '../../core/services/auth_service.dart';
import '../../shared/widgets/app_feedback.dart';
import 'admin_commission_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_withdrawals_screen.dart';
import 'categories/admin_categories_screen.dart';
import 'customers/admin_customers_screen.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'services/admin_services_screen.dart';
import 'technicians/admin_technicians_screen.dart';

// ─── Warna Branding Si Teknisi ───────────────────────────────────────────────
abstract class AppColors {
  static const primaryBlue = Color(0xFF0D72BD);
  static const secondaryBlue = Color(0xFF2283C6);
  static const lightBlue = Color(0xFF3A97D3);
  static const softBlue = Color(0xFFA1C9E4);
  static const darkBlue = Color(0xFF0A4F86);
  static const bgPage = Color(0xFFF5F9FC);
  static const cardWhite = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCEAF4);
  static const iconBg = Color(0xFFEAF5FC);
  static const textPrimary = Color(0xFF16324F);
  static const textSecondary = Color(0xFF64748B);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // alias tetap agar screen lama tidak rusak
  static const primary = primaryBlue;
  static const background = bgPage;
  static const teal = lightBlue;
  static const amber = warning;

  static const sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBlue, primaryBlue],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, primaryBlue, lightBlue],
    stops: [0.0, 0.55, 1.0],
  );
}

// ─── Nav Item ────────────────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
  final IconData icon;
  final String label;
  final int index;
}

// ─── Admin Shell ─────────────────────────────────────────────────────────────
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
  bool _sidebarCollapsed = false;

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0),
    _NavItem(icon: Icons.people_outline, label: 'Customer', index: 1),
    _NavItem(icon: Icons.engineering_outlined, label: 'Teknisi', index: 2),
    _NavItem(
      icon: Icons.verified_user_outlined,
      label: 'Verifikasi Teknisi',
      index: 3,
    ),
    _NavItem(icon: Icons.category_outlined, label: 'Kategori', index: 4),
    _NavItem(icon: Icons.build_outlined, label: 'Layanan', index: 5),
    _NavItem(icon: Icons.receipt_long_outlined, label: 'Order', index: 6),
    _NavItem(icon: Icons.payment_outlined, label: 'Pembayaran', index: 7),
    _NavItem(icon: Icons.star_outline_rounded, label: 'Ulasan', index: 8),
    _NavItem(icon: Icons.percent_outlined, label: 'Komisi', index: 9),
    _NavItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Penarikan',
      index: 10,
    ),
    _NavItem(icon: Icons.bar_chart_outlined, label: 'Laporan', index: 11),
    _NavItem(icon: Icons.settings_outlined, label: 'Pengaturan', index: 12),
  ];

  List<Widget> get _screens => [
    const AdminDashboardScreen(),
    const AdminCustomersScreen(),
    const AdminTechniciansScreen(),
    const AdminTechniciansScreen(), // verifikasi - reuse dgn filter pending
    const AdminCategoriesScreen(),
    const AdminServicesScreen(),
    const AdminOrdersScreen(),
    const AdminPaymentsScreen(),
    const AdminReviewsScreen(),
    const AdminCommissionScreen(),
    const AdminWithdrawalsScreen(),
    const AdminReportsScreen(),
    const AdminSettingsScreen(),
  ];

  Future<void> _confirmSignOut() async {
    if (!await AppFeedback.confirmLogout(context)) return;
    await widget.authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    if (!isWide) {
      return _MobileLayout(
        navItems: _navItems,
        screens: _screens,
        selectedIndex: _selectedIndex,
        profile: widget.profile,
        onSelect: (i) => setState(() => _selectedIndex = i),
        onSignOut: _confirmSignOut,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Row(
        children: [
          _Sidebar(
            items: _navItems,
            selectedIndex: _selectedIndex,
            profile: widget.profile,
            collapsed: _sidebarCollapsed,
            onSelect: (i) => setState(() => _selectedIndex = i),
            onSignOut: _confirmSignOut,
            onToggleCollapse: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
          ),
          Expanded(
            child: Column(
              children: [
                _Topbar(
                  title: _navItems[_selectedIndex].label,
                  profile: widget.profile,
                  onToggleSidebar: () =>
                      setState(() => _sidebarCollapsed = !_sidebarCollapsed),
                  onSignOut: _confirmSignOut,
                ),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.profile,
    required this.collapsed,
    required this.onSelect,
    required this.onSignOut,
    required this.onToggleCollapse,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final AppUserProfile profile;
  final bool collapsed;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 72.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: w,
      decoration: const BoxDecoration(
        gradient: AppColors.sidebarGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x330A4F86),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Logo area ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.fromLTRB(
              collapsed ? 12 : 20,
              28,
              collapsed ? 12 : 20,
              20,
            ),
            child: collapsed
                ? Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/logos/logoku.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/logos/logoku.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Si Teknisi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Solusi Cepat, Hasil Tepat',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Divider ──
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 20),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 12),

          // ── Menu items ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 8 : 12,
                vertical: 0,
              ),
              children: items.map((item) {
                final selected = item.index == selectedIndex;
                return _SidebarItem(
                  item: item,
                  selected: selected,
                  collapsed: collapsed,
                  onTap: () => onSelect(item.index),
                );
              }).toList(),
            ),
          ),

          // ── Bottom user info ──
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 20),
            color: Colors.white.withValues(alpha: 0.12),
          ),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Administrator',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onSignOut,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.logout_outlined,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: IconButton(
                icon: Icon(
                  Icons.logout_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
                onPressed: onSignOut,
                tooltip: 'Keluar',
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });
  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    final hovered = _hovered && !active;

    return Tooltip(
      message: widget.collapsed ? widget.item.label : '',
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 2),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.18)
                  : hovered
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border(
                      left: const BorderSide(color: Colors.white, width: 3),
                    )
                  : null,
            ),
            child: widget.collapsed
                ? Center(
                    child: Icon(
                      widget.item.icon,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.65),
                      size: 20,
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 4),
                      Icon(
                        widget.item.icon,
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.65),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.72),
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Topbar ──────────────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.title,
    required this.profile,
    required this.onToggleSidebar,
    required this.onSignOut,
  });

  final String title;
  final AppUserProfile profile;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x080A4F86),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleSidebar,
            icon: const Icon(Icons.menu_rounded, size: 22),
            color: AppColors.textSecondary,
            tooltip: 'Toggle Sidebar',
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),

          // Search
          Container(
            width: 220,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Cari...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                prefixIcon: Icon(
                  Icons.search_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Notif
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Profile
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName.isEmpty ? 'Admin' : profile.fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Admin Si Teknisi',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_outlined,
                          size: 16,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Keluar',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'logout') onSignOut();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Layout ────────────────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.navItems,
    required this.screens,
    required this.selectedIndex,
    required this.profile,
    required this.onSelect,
    required this.onSignOut,
  });

  final List<_NavItem> navItems;
  final List<Widget> screens;
  final int selectedIndex;
  final AppUserProfile profile;
  final ValueChanged<int> onSelect;
  final VoidCallback onSignOut;

  // Only show first 5 items in bottom nav
  static const _bottomCount = 5;

  @override
  Widget build(BuildContext context) {
    final bottomItems = navItems.take(_bottomCount).toList();
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logos/logoku.png', width: 28, height: 28),
            const SizedBox(width: 8),
            const Text(
              'Si Teknisi Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: onSignOut,
          ),
        ],
      ),
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < _bottomCount ? selectedIndex : 0,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.iconBg,
        onDestinationSelected: onSelect,
        destinations: bottomItems
            .map(
              (e) => NavigationDestination(
                icon: Icon(e.icon, color: AppColors.textSecondary),
                selectedIcon: Icon(e.icon, color: AppColors.primaryBlue),
                label: e.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Placeholder Screen ───────────────────────────────────────────────────────
// ─── Shared Admin Widgets ─────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      color: AppColors.bgPage,
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
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrimaryButton(
            icon: Icons.refresh_outlined,
            label: 'Refresh',
            onPressed: onRefresh,
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.iconBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: AppColors.softBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    required this.label,
    required this.color,
    required this.bg,
    super.key,
  });
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Reusable Primary Button ──────────────────────────────────────────────────
class AdminDataCard extends StatelessWidget {
  const AdminDataCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080A4F86),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminInfoChip extends StatelessWidget {
  const AdminInfoChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgPage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminMetricTile extends StatelessWidget {
  const AdminMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String formatRupiah(double amount) {
  if (amount == 0) return 'Rp 0';
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.check_outlined, size: 16, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
