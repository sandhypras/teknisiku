import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  late Future<List<OrderSummary>> _future;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.customerOrders();
  }

  void _refresh() => setState(() {
    _future = widget.repo.customerOrders();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<OrderSummary>>(
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
          final orders = _filtered(snapshot.data ?? []);
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const _OrdersHeader(),
                const SizedBox(height: 22),
                _OrderTabs(
                  selected: _tab,
                  onChanged: (value) => setState(() => _tab = value),
                ),
                const SizedBox(height: 22),
                if (orders.isEmpty)
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    child: const EmptyState(message: 'Belum ada pesanan'),
                  )
                else
                  for (final order in orders) ...[
                    _CustomerOrderCard(order: order),
                    const SizedBox(height: 14),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<OrderSummary> _filtered(List<OrderSummary> orders) {
    return switch (_tab) {
      1 => orders.where((item) => item.status == 'completed').toList(),
      2 =>
        orders
            .where(
              (item) =>
                  item.status == 'rejected' || item.status == 'price_rejected',
            )
            .toList(),
      _ =>
        orders
            .where(
              (item) =>
                  item.status != 'completed' &&
                  item.status != 'rejected' &&
                  item.status != 'price_rejected',
            )
            .toList(),
    };
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLogoMark(size: 64),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Si Teknisi',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Solusi Cepat, Hasil Tepat',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Pesanan Pelanggan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Kelola pesanan layanan Anda dengan mudah.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderIconButton(icon: Icons.notifications_none_rounded),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3030),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
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
    const labels = ['Aktif', 'Selesai', 'Ditolak'];
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4ECF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected == index
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: selected == index
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: selected == index ? 112 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
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

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4ECF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.orderNumber.replaceAll('#', '')}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              _OrderStatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.technicianName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _MetaLine(
                      icon: categoryIcon(order.problemDescription),
                      text: order.problemDescription.isEmpty
                          ? 'Layanan teknisi'
                          : order.problemDescription,
                    ),
                    _MetaLine(
                      icon: Icons.calendar_month_outlined,
                      text:
                          '${_friendlyDate(order.scheduleDate)}, ${_shortTime(order.scheduleTime)}',
                    ),
                    _MetaLine(
                      icon: Icons.location_on_rounded,
                      text: [
                        order.address,
                        order.city,
                      ].where((item) => (item ?? '').isNotEmpty).join(', '),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Estimasi Total',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_showTimeline(order.status)) ...[
            const SizedBox(height: 18),
            _OrderTimeline(status: order.status, createdAt: order.createdAt),
          ],
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Text(
                  'Lihat Detail',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Spacer(),
                Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusPill extends StatelessWidget {
  const _OrderStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            orderStatusLabel(status),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.status, required this.createdAt});

  final String status;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final active = _statusStep(status);
    final labels = [
      'Pesanan Masuk',
      'Diterima Teknisi',
      'Sedang Dikerjakan',
      'Selesai',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EEF9)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: index <= active ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index <= active
                            ? AppColors.primary
                            : const Color(0xFFB8C5D8),
                      ),
                    ),
                    child: Icon(
                      index <= active
                          ? Icons.check_rounded
                          : Icons.flag_outlined,
                      color: index <= active
                          ? Colors.white
                          : AppColors.textSecondary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: index == active
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    index == 0 && createdAt != null
                        ? _dateOnly(createdAt!)
                        : '-',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (index != labels.length - 1)
              Container(
                width: 18,
                height: 2,
                color: index < active
                    ? AppColors.primary
                    : const Color(0xFFD3DEEC),
              ),
          ],
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

bool _showTimeline(String status) {
  return status != 'waiting_confirmation' &&
      status != 'rejected' &&
      status != 'price_rejected' &&
      status != 'completed';
}

IconData _statusIcon(String status) => switch (status) {
  'waiting_confirmation' => Icons.access_time_rounded,
  'accepted' => Icons.check_circle_rounded,
  'in_progress' => Icons.build_rounded,
  'completed' => Icons.check_circle_rounded,
  'rejected' || 'price_rejected' => Icons.cancel_rounded,
  _ => Icons.info_outline_rounded,
};

int _statusStep(String status) => switch (status) {
  'accepted' || 'on_the_way' || 'inspection' || 'waiting_price_approval' => 1,
  'in_progress' || 'waiting_payment' => 2,
  'completed' => 3,
  _ => 0,
};

String _friendlyDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

String _dateOnly(DateTime value) => '${value.day}/${value.month}';

String _shortTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}
