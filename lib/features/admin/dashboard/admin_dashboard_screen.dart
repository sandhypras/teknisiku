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
      db.from('services').select('id').eq('approval_status', 'pending'),
      db.from('orders').select('id'),
      db.from('payments').select('amount').eq('payment_status', 'paid'),
      db.from('categories').select('id').eq('is_active', true),
      db
          .from('payments')
          .select('id')
          .eq('payment_status', 'waiting_verification'),
      db.from('technician_documents').select('id'),
    ]);

    final totalRevenue = (results[5] as List).fold<double>(
      0,
      (sum, r) => sum + (r['amount'] as num).toDouble(),
    );

    return _DashboardStats(
      customers: (results[0] as List).length,
      technicians: (results[1] as List).length,
      pendingTechnicians: (results[2] as List).length,
      pendingServices: (results[3] as List).length,
      orders: (results[4] as List).length,
      totalRevenue: totalRevenue,
      activeCategories: (results[6] as List).length,
      pendingPayments: (results[7] as List).length,
      uploadedDocuments: (results[8] as List).length,
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
                  loading: snapshot.connectionState == ConnectionState.waiting,
                  onRefresh: () => setState(() {
                    _statsFuture = _fetchStats();
                  }),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  child: _ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _statsFuture = _fetchStats();
                    }),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _StatsGrid(stats: snapshot.data!)),
                SliverToBoxAdapter(child: _AlertBanners(stats: snapshot.data!)),
                SliverToBoxAdapter(child: _RecentOrdersSection()),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, required this.loading});
  final VoidCallback onRefresh;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF4F8FE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.space_dashboard_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Text(
                    'Ringkasan data Si Teknisi',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        loading ? 'Memuat data...' : 'Data terbaru',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(loading ? 'Memuat...' : 'Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        label: 'Kategori Aktif',
        value: stats.activeCategories.toString(),
        icon: Icons.category_rounded,
        color: AppColors.primaryBlue,
      ),
      _StatCard(
        label: 'Pembayaran Verifikasi',
        value: stats.pendingPayments.toString(),
        icon: Icons.payments_rounded,
        color: stats.pendingPayments > 0
            ? AppColors.warning
            : AppColors.success,
        highlight: stats.pendingPayments > 0,
      ),
      _StatCard(
        label: 'Dokumen Teknisi',
        value: stats.uploadedDocuments.toString(),
        icon: Icons.badge_rounded,
        color: AppColors.teal,
      ),
      _StatCard(
        label: 'Total Pendapatan',
        value: _formatCurrency(stats.totalRevenue),
        icon: Icons.account_balance_wallet_rounded,
        color: AppColors.success,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
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

class _StatCard extends StatefulWidget {
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
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: widget.highlight
              ? Border.all(
                  color: widget.color.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : Border.all(color: Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.09 : 0.05),
              blurRadius: _hovering ? 14 : 8,
              offset: Offset(0, _hovering ? 5 : 2),
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
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: widget.highlight
                              ? widget.color
                              : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (widget.highlight) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      alerts.add(
        _AlertBanner(
          icon: Icons.person_search_rounded,
          message: '${stats.pendingTechnicians} teknisi menunggu verifikasi',
          color: AppColors.warning,
        ),
      );
    }
    if (stats.pendingServices > 0) {
      alerts.add(
        _AlertBanner(
          icon: Icons.build_circle_rounded,
          message: '${stats.pendingServices} layanan menunggu persetujuan',
          color: AppColors.teal,
        ),
      );
    }
    if (stats.pendingPayments > 0) {
      alerts.add(
        _AlertBanner(
          icon: Icons.payment_rounded,
          message: '${stats.pendingPayments} pembayaran menunggu verifikasi',
          color: AppColors.warning,
        ),
      );
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 16,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                'Perlu perhatian',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...alerts.map(
            (a) => Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: color.withValues(alpha: 0.6),
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersSection extends StatefulWidget {
  @override
  State<_RecentOrdersSection> createState() => _RecentOrdersSectionState();
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
          'order_number, status, final_total, created_at, customer:profiles!customer_id(full_name)',
        )
        .order('created_at', ascending: false)
        .limit(8);
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Pesanan Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEF1F5)),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 36,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Belum ada pesanan',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    const _OrderTableHeader(),
                    for (var i = 0; i < orders.length; i++)
                      _OrderRow(
                        order: orders[i],
                        isLast: i == orders.length - 1,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTableHeader extends StatelessWidget {
  const _OrderTableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.background,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('NO. PESANAN', style: style)),
          Expanded(flex: 2, child: Text('CUSTOMER', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(
            flex: 2,
            child: Text('TOTAL', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, this.isLast = false});
  final Map<String, dynamic> order;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? '';
    final statusStyle = _orderStatusStyle(status);
    final customer = order['customer'] as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order['order_number'] as String? ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              customer?['full_name'] as String? ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusStyle.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusStyle.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusStyle.color,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency((order['final_total'] as num?)?.toDouble() ?? 0),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
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
      'Menunggu',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.1),
    ),
    'accepted' => _StatusStyle(
      'Diterima',
      AppColors.teal,
      AppColors.teal.withValues(alpha: 0.1),
    ),
    'on_the_way' => _StatusStyle(
      'Di Jalan',
      AppColors.teal,
      AppColors.teal.withValues(alpha: 0.1),
    ),
    'inspection' => _StatusStyle(
      'Inspeksi',
      const Color(0xFF8B5CF6),
      const Color(0xFF8B5CF6).withValues(alpha: 0.1),
    ),
    'waiting_price_approval' => _StatusStyle(
      'Tunggu Biaya',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.1),
    ),
    'in_progress' => _StatusStyle(
      'Dikerjakan',
      AppColors.primary,
      AppColors.primary.withValues(alpha: 0.1),
    ),
    'waiting_payment' => _StatusStyle(
      'Tunggu Bayar',
      AppColors.amber,
      AppColors.amber.withValues(alpha: 0.15),
    ),
    'completed' => _StatusStyle(
      'Selesai',
      AppColors.success,
      AppColors.success.withValues(alpha: 0.1),
    ),
    'rejected' => _StatusStyle(
      'Ditolak',
      AppColors.error,
      AppColors.error.withValues(alpha: 0.1),
    ),
    'price_rejected' => _StatusStyle(
      'Biaya Ditolak',
      AppColors.error,
      AppColors.error.withValues(alpha: 0.1),
    ),
    _ => _StatusStyle(
      'Unknown',
      AppColors.textSecondary,
      AppColors.textSecondary.withValues(alpha: 0.1),
    ),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat data',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba lagi'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
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
    required this.activeCategories,
    required this.pendingPayments,
    required this.uploadedDocuments,
  });

  final int customers;
  final int technicians;
  final int pendingTechnicians;
  final int pendingServices;
  final int orders;
  final double totalRevenue;
  final int activeCategories;
  final int pendingPayments;
  final int uploadedDocuments;
}
