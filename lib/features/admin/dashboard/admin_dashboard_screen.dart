import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<_DashboardStats> _fetchStats() async {
    final db = Supabase.instance.client;

    final results = await Future.wait([
      db.from('profiles').select('id').eq('role', 'customer'),
      db.from('profiles').select('id').eq('role', 'technician'),
      db
          .from('technician_profiles')
          .select('id')
          .eq('verification_status', 'pending'),
      db
          .from('services')
          .select('id')
          .eq('approval_status', 'pending'),
      db.from('orders').select('id'),
      db
          .from('payments')
          .select('amount')
          .eq('payment_status', 'paid'),
    ]);

    final totalRevenue = (results[5] as List)
        .fold<double>(0, (sum, r) => sum + (r['amount'] as num).toDouble());

    return _DashboardStats(
      customers: (results[0] as List).length,
      technicians: (results[1] as List).length,
      pendingTechnicians: (results[2] as List).length,
      pendingServices: (results[3] as List).length,
      orders: (results[4] as List).length,
      totalRevenue: totalRevenue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  onRefresh: () =>
                      setState(() => _statsFuture = _fetchStats()),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () =>
                        setState(() => _statsFuture = _fetchStats()),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: _StatsGrid(stats: snapshot.data!),
                ),
                SliverToBoxAdapter(
                  child: _AlertBanners(stats: snapshot.data!),
                ),
                SliverToBoxAdapter(
                  child: _RecentOrdersSection(),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Ringkasan data Si Teknisi',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        label: 'Total Customer',
        value: stats.customers.toString(),
        icon: Icons.people_alt_rounded,
        color: AppColors.teal,
      ),
      _StatCard(
        label: 'Total Teknisi',
        value: stats.technicians.toString(),
        icon: Icons.engineering_rounded,
        color: AppColors.primary,
      ),
      _StatCard(
        label: 'Menunggu Verifikasi',
        value: stats.pendingTechnicians.toString(),
        icon: Icons.pending_actions_rounded,
        color: stats.pendingTechnicians > 0
            ? AppColors.warning
            : AppColors.success,
        highlight: stats.pendingTechnicians > 0,
      ),
      _StatCard(
        label: 'Layanan Pending',
        value: stats.pendingServices.toString(),
        icon: Icons.build_circle_rounded,
        color: stats.pendingServices > 0
            ? AppColors.warning
            : AppColors.success,
        highlight: stats.pendingServices > 0,
      ),
      _StatCard(
        label: 'Total Pesanan',
        value: stats.orders.toString(),
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _StatCard(
        label: 'Total Pendapatan',
        value: _formatCurrency(stats.totalRevenue),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxis = constraints.maxWidth > 900
              ? 3
              : constraints.maxWidth > 600
                  ? 2
                  : 1;
          return GridView.count(
            crossAxisCount: crossAxis,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.4,
            children: cards,
          );
        },
      ),
    );
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: color.withValues(alpha: 0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: highlight ? color : AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanners extends StatelessWidget {
  const _AlertBanners({required this.stats});
  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final alerts = <Widget>[];

    if (stats.pendingTechnicians > 0) {
      alerts.add(_AlertBanner(
        icon: Icons.person_search_rounded,
        message:
            '${stats.pendingTechnicians} teknisi menunggu verifikasi',
        color: AppColors.warning,
      ));
    }
    if (stats.pendingServices > 0) {
      alerts.add(_AlertBanner(
        icon: Icons.build_circle_rounded,
        message:
            '${stats.pendingServices} layanan menunggu persetujuan',
        color: AppColors.teal,
      ));
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: alerts
            .map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: a,
                ))
            .toList(),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersSection extends StatefulWidget {
  @override
  State<_RecentOrdersSection> createState() =>
      _RecentOrdersSectionState();
}

class _RecentOrdersSectionState extends State<_RecentOrdersSection> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchRecentOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchRecentOrders() async {
    final data = await Supabase.instance.client
        .from('orders')
        .select(
            'order_number, status, final_total, created_at, customer:profiles!customer_id(full_name)')
        .order('created_at', ascending: false)
        .limit(8);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Pesanan Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Belum ada pesanan',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return Column(
                  children: orders
                      .map((o) => _OrderRow(order: o))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? '';
    final statusStyle = _orderStatusStyle(status);
    final customer = order['customer'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order['order_number'] as String? ?? '-',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customer?['full_name'] as String? ?? '-',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusStyle.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusStyle.label,
                style: TextStyle(
                    fontSize: 11,
                    color: statusStyle.color,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(
                  (order['final_total'] as num?)?.toDouble() ?? 0),
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) {
    if (amount == 0) return '-';
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}

_StatusStyle _orderStatusStyle(String status) {
  return switch (status) {
    'waiting_confirmation' => _StatusStyle(
        'Menunggu', AppColors.warning, AppColors.warning.withValues(alpha: 0.1)),
    'accepted' => _StatusStyle(
        'Diterima', AppColors.teal, AppColors.teal.withValues(alpha: 0.1)),
    'on_the_way' => _StatusStyle(
        'Di Jalan', AppColors.teal, AppColors.teal.withValues(alpha: 0.1)),
    'inspection' => _StatusStyle(
        'Inspeksi', const Color(0xFF8B5CF6),
        const Color(0xFF8B5CF6).withValues(alpha: 0.1)),
    'waiting_price_approval' => _StatusStyle(
        'Tunggu Biaya', AppColors.warning,
        AppColors.warning.withValues(alpha: 0.1)),
    'in_progress' => _StatusStyle(
        'Dikerjakan', AppColors.primary,
        AppColors.primary.withValues(alpha: 0.1)),
    'waiting_payment' => _StatusStyle(
        'Tunggu Bayar', AppColors.amber,
        AppColors.amber.withValues(alpha: 0.15)),
    'completed' => _StatusStyle(
        'Selesai', AppColors.success,
        AppColors.success.withValues(alpha: 0.1)),
    'rejected' => _StatusStyle(
        'Ditolak', AppColors.error, AppColors.error.withValues(alpha: 0.1)),
    'price_rejected' => _StatusStyle(
        'Biaya Ditolak', AppColors.error,
        AppColors.error.withValues(alpha: 0.1)),
    _ => _StatusStyle('Unknown', AppColors.textSecondary,
        AppColors.textSecondary.withValues(alpha: 0.1)),
  };
}

class _StatusStyle {
  const _StatusStyle(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Gagal memuat data',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.customers,
    required this.technicians,
    required this.pendingTechnicians,
    required this.pendingServices,
    required this.orders,
    required this.totalRevenue,
  });

  final int customers;
  final int technicians;
  final int pendingTechnicians;
  final int pendingServices;
  final int orders;
  final double totalRevenue;
}
