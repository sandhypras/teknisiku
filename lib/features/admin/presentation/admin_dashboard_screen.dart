import 'package:flutter/material.dart';

import '../../../core/models/app_user_profile.dart';
import '../../../core/services/auth_service.dart';
import '../data/admin_dashboard_service.dart';
import '../models/admin_dashboard_summary.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    required this.profile,
    required this.authService,
    required this.dashboardService,
    super.key,
  });

  final AppUserProfile profile;
  final AuthService authService;
  final AdminDashboardService dashboardService;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.dashboardService.loadSummary();
  }

  void _refresh() {
    setState(() {
      _summaryFuture = widget.dashboardService.loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: const Color(0xFFF6F8FA),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<AdminDashboardSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _AdminErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final summary = snapshot.data;
          if (summary == null) {
            return _AdminErrorState(
              message: 'Data dashboard belum tersedia.',
              onRetry: _refresh,
            );
          }

          return _AdminDashboardContent(
            profile: widget.profile,
            summary: summary,
          );
        },
      ),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent({required this.profile, required this.summary});

  final AppUserProfile profile;
  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminHeader(profile: profile, summary: summary),
                  const SizedBox(height: 20),
                  _MetricGrid(summary: summary),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _RecentOrdersPanel(
                            orders: summary.recentOrders,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _PendingWorkPanel(summary: summary),
                        ),
                      ],
                    )
                  else ...[
                    _RecentOrdersPanel(orders: summary.recentOrders),
                    const SizedBox(height: 16),
                    _PendingWorkPanel(summary: summary),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.profile, required this.summary});

  final AppUserProfile profile;
  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16324F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName.isEmpty ? profile.email : profile.fullName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Solo service operation',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          _HeaderStatusPill(
            label: '${summary.pendingTechnicians + summary.pendingServices}',
            caption: 'antrian approval',
          ),
        ],
      ),
    );
  }
}

class _HeaderStatusPill extends StatelessWidget {
  const _HeaderStatusPill({required this.label, required this.caption});

  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00A6A6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            caption,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary});

  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        title: 'Customer',
        value: summary.totalCustomers.toString(),
        icon: Icons.people_alt_outlined,
        tone: const Color(0xFF16324F),
      ),
      _MetricData(
        title: 'Teknisi',
        value: summary.totalTechnicians.toString(),
        icon: Icons.engineering_outlined,
        tone: const Color(0xFF00A6A6),
      ),
      _MetricData(
        title: 'Teknisi pending',
        value: summary.pendingTechnicians.toString(),
        icon: Icons.verified_user_outlined,
        tone: const Color(0xFFF59E0B),
      ),
      _MetricData(
        title: 'Layanan pending',
        value: summary.pendingServices.toString(),
        icon: Icons.fact_check_outlined,
        tone: const Color(0xFFF4A261),
      ),
      _MetricData(
        title: 'Pesanan',
        value: summary.totalOrders.toString(),
        icon: Icons.receipt_long_outlined,
        tone: const Color(0xFF1F2937),
      ),
      _MetricData(
        title: 'Pesanan aktif',
        value: summary.activeOrders.toString(),
        icon: Icons.timeline_outlined,
        tone: const Color(0xFF22C55E),
      ),
      _MetricData(
        title: 'Pembayaran cek',
        value: summary.waitingPayments.toString(),
        icon: Icons.payments_outlined,
        tone: const Color(0xFFEF4444),
      ),
      _MetricData(
        title: 'Transaksi paid',
        value: _formatCurrency(summary.totalTransaction),
        icon: Icons.account_balance_wallet_outlined,
        tone: const Color(0xFF16324F),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1080
            ? 4
            : width >= 760
            ? 3
            : width >= 520
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 122,
          ),
          itemBuilder: (context, index) {
            return _MetricCard(data: metrics[index]);
          },
        );
      },
    );
  }

  static String _formatCurrency(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final indexFromEnd = text.length - i;
      buffer.write(text[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp$buffer';
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color tone;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.tone),
              const Spacer(),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: data.tone,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentOrdersPanel extends StatelessWidget {
  const _RecentOrdersPanel({required this.orders});

  final List<AdminRecentOrder> orders;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Pesanan terbaru',
      child: orders.isEmpty
          ? const _EmptyPanelText('Belum ada pesanan.')
          : Column(
              children: [for (final order in orders) _OrderRow(order: order)],
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final AdminRecentOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              order.orderNumber,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusBadge(status: order.status),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _MetricGrid._formatCurrency(order.finalTotal),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingWorkPanel extends StatelessWidget {
  const _PendingWorkPanel({required this.summary});

  final AdminDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Butuh review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QueueBlock(
            title: 'Teknisi pending',
            items: summary.pendingTechnicianIds,
            emptyText: 'Tidak ada teknisi pending.',
          ),
          const Divider(height: 28),
          _QueueBlock(
            title: 'Layanan pending',
            items: summary.pendingServiceNames,
            emptyText: 'Tidak ada layanan pending.',
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.star_rate_rounded, color: Color(0xFFF59E0B)),
              const SizedBox(width: 8),
              Text(
                summary.averageRating == 0
                    ? 'Belum ada rating'
                    : 'Rating rata-rata ${summary.averageRating.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueBlock extends StatelessWidget {
  const _QueueBlock({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  final String title;
  final List<String> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _EmptyPanelText(emptyText)
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => const Color(0xFF22C55E),
      'rejected' || 'price_rejected' => const Color(0xFFEF4444),
      'waiting_payment' || 'waiting_price_approval' => const Color(0xFFF59E0B),
      _ => const Color(0xFF00A6A6),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyPanelText extends StatelessWidget {
  const _EmptyPanelText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: Color(0xFF6B7280)));
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
