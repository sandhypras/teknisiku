import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'technician_shell_page.dart';

class TechnicianDashboardPage extends StatefulWidget {
  const TechnicianDashboardPage({
    required this.profile,
    required this.repo,
    super.key,
  });

  final AppProfile profile;
  final MarketplaceRepository repo;

  @override
  State<TechnicianDashboardPage> createState() =>
      _TechnicianDashboardPageState();
}

class _TechnicianDashboardPageState extends State<TechnicianDashboardPage> {
  late Future<_TechnicianDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TechnicianDashboardData> _load() async {
    final technician = await widget.repo.myTechnicianProfile();
    final orders = technician == null
        ? <OrderSummary>[]
        : await widget.repo.technicianOrders(technician.id);
    return _TechnicianDashboardData(technician: technician, orders: orders);
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_TechnicianDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final data = snapshot.data!;
          final technician = data.technician;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                TechnicianHeader(
                  title: 'Halo, ${widget.profile.fullName}',
                  subtitle: 'Dashboard teknisi terhubung Supabase',
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: _VerificationCard(technician: technician),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: MobileSectionHeader(
                    title: 'Pesanan masuk',
                    subtitle: '${data.orders.length} pesanan',
                    action: TextButton(
                      onPressed: _refresh,
                      child: const Text('Sync'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (technician == null)
                  const SizedBox(
                    height: 260,
                    child: EmptyState(
                      message: 'Lengkapi profil teknisi dulu',
                      icon: Icons.badge_outlined,
                    ),
                  )
                else if (data.orders.isEmpty)
                  const SizedBox(
                    height: 260,
                    child: EmptyState(message: 'Belum ada pesanan masuk'),
                  )
                else
                  for (final order in data.orders)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: _TechnicianOrderCard(
                        order: order,
                        onStatus: (status) async {
                          await widget.repo.updateOrderStatus(order.id, status);
                          _refresh();
                        },
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({required this.technician});

  final TechnicianSummary? technician;

  @override
  Widget build(BuildContext context) {
    final status = technician?.status ?? 'belum lengkap';
    final color = switch (status) {
      'verified' => AppColors.success,
      'rejected' || 'inactive' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Verifikasi',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == 'verified'
                      ? 'Kamu bisa membuat layanan dan menerima pesanan.'
                      : 'Tunggu admin memverifikasi profil dan dokumen kamu.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.verified_user_rounded, color: color),
          ),
        ],
      ),
    );
  }
}

class _TechnicianOrderCard extends StatelessWidget {
  const _TechnicianOrderCard({required this.order, required this.onStatus});

  final OrderSummary order;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              StatusPill(label: orderStatusLabel(order.status), color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: ${order.customerName}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            'Jadwal: ${order.scheduleDate} ${order.scheduleTime}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(order.problemDescription),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.status == 'waiting_confirmation') ...[
                FilledButton(
                  onPressed: () => onStatus('accepted'),
                  child: const Text('Terima'),
                ),
                OutlinedButton(
                  onPressed: () => onStatus('rejected'),
                  child: const Text('Tolak'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => onStatus(_nextStatus(order.status)),
                  child: Text(
                    'Ubah ke ${orderStatusLabel(_nextStatus(order.status))}',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _nextStatus(String status) => switch (status) {
    'accepted' => 'on_the_way',
    'on_the_way' => 'inspection',
    'inspection' => 'waiting_price_approval',
    'waiting_price_approval' => 'in_progress',
    'in_progress' => 'waiting_payment',
    'waiting_payment' => 'completed',
    _ => status,
  };
}

class _TechnicianDashboardData {
  const _TechnicianDashboardData({
    required this.technician,
    required this.orders,
  });

  final TechnicianSummary? technician;
  final List<OrderSummary> orders;
}
