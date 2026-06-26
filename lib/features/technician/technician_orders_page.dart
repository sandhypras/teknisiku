import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';

class TechnicianOrdersPage extends StatefulWidget {
  const TechnicianOrdersPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<TechnicianOrdersPage> createState() => _TechnicianOrdersPageState();
}

class _TechnicianOrdersPageState extends State<TechnicianOrdersPage> {
  late Future<_TechnicianOrdersData> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TechnicianOrdersData> _load() async {
    final technician = await widget.repo.myTechnicianProfile();
    final orders = technician == null
        ? <OrderSummary>[]
        : await widget.repo.technicianOrders(technician.id);
    return _TechnicianOrdersData(technician: technician, orders: orders);
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F8FF), Color(0xFFFAFCFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_TechnicianOrdersData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            final filtered = _filtered(data.orders);
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  const _OrdersHeader(),
                  const SizedBox(height: 18),
                  _OrderTabs(
                    selected: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                  const SizedBox(height: 18),
                  if (data.technician == null)
                    const SizedBox(
                      height: 320,
                      child: EmptyState(
                        message: 'Lengkapi profil teknisi dulu',
                        icon: Icons.badge_outlined,
                      ),
                    )
                  else if (filtered.isEmpty)
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: EmptyState(
                        message: _emptyMessage,
                        icon: Icons.assignment_outlined,
                      ),
                    )
                  else
                    for (final order in filtered) ...[
                      _OrderCard(
                        order: order,
                        onStatus: (status) async {
                          await widget.repo.updateOrderStatus(order.id, status);
                          _refresh();
                        },
                        onDetail: () => _showOrderDetail(order),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String get _emptyMessage => switch (_tab) {
    1 => 'Belum ada order yang sedang diproses',
    2 => 'Belum ada order selesai',
    3 => 'Belum ada order ditolak',
    _ => 'Belum ada order baru',
  };

  List<OrderSummary> _filtered(List<OrderSummary> orders) {
    return switch (_tab) {
      1 =>
        orders
            .where(
              (item) =>
                  item.status != 'waiting_confirmation' &&
                  item.status != 'completed' &&
                  item.status != 'rejected' &&
                  item.status != 'price_rejected',
            )
            .toList(),
      2 => orders.where((item) => item.status == 'completed').toList(),
      3 =>
        orders
            .where(
              (item) =>
                  item.status == 'rejected' || item.status == 'price_rejected',
            )
            .toList(),
      _ =>
        orders.where((item) => item.status == 'waiting_confirmation').toList(),
    };
  }

  void _showOrderDetail(OrderSummary order) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              _DetailLine('Customer', order.customerName),
              _DetailLine('Telepon', order.customerPhone ?? '-'),
              _DetailLine('Status', orderStatusLabel(order.status)),
              _DetailLine(
                'Jadwal',
                '${order.scheduleDate} ${order.scheduleTime}',
              ),
              _DetailLine(
                'Alamat',
                [
                  order.address,
                  order.city,
                ].where((item) => (item ?? '').isNotEmpty).join(', '),
              ),
              _DetailLine('Estimasi', formatRupiah(total)),
              const Divider(height: 26),
              const Text(
                'Deskripsi Masalah',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                order.problemDescription.isEmpty
                    ? 'Tidak ada deskripsi'
                    : order.problemDescription,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoMark(size: 58),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Saya',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Kelola pekerjaan teknisi dari Supabase',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: _cardDecoration(radius: 15),
          child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Baru', 'Proses', 'Selesai', 'Ditolak'];
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: _cardDecoration(radius: 14),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == index
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected == index
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onStatus,
    required this.onDetail,
  });

  final OrderSummary order;
  final ValueChanged<String> onStatus;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    final statusColor = orderStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: orderStatusLabel(order.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  categoryIcon(order.problemDescription),
                  color: AppColors.primary,
                  size: 39,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.problemDescription.isEmpty
                          ? 'Permintaan Layanan'
                          : order.problemDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _MetaLine(
                      icon: Icons.person_outline_rounded,
                      text: [
                        order.customerName,
                        order.customerPhone,
                      ].where((item) => (item ?? '').isNotEmpty).join(' - '),
                    ),
                    _MetaLine(
                      icon: Icons.location_on_outlined,
                      text: [
                        order.address,
                        order.city,
                      ].where((item) => (item ?? '').isNotEmpty).join(', '),
                    ),
                    _MetaLine(
                      icon: Icons.calendar_month_outlined,
                      text: '${order.scheduleDate} ${order.scheduleTime}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onDetail, child: const Text('Detail')),
            ],
          ),
          _ActionRow(order: order, onStatus: onStatus),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.order, required this.onStatus});

  final OrderSummary order;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    if (order.status == 'waiting_confirmation') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onStatus('rejected'),
              child: const Text('Tolak'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => onStatus('accepted'),
              child: const Text('Terima'),
            ),
          ),
        ],
      );
    }
    final next = _nextStatus(order.status);
    if (next == order.status) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => onStatus(next),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text('Ubah ke ${orderStatusLabel(next)}'),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianOrdersData {
  const _TechnicianOrdersData({required this.technician, required this.orders});

  final TechnicianSummary? technician;
  final List<OrderSummary> orders;
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

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE4ECF6)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
