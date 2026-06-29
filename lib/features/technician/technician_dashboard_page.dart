import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';

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
          stops: [0.0, 0.32],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_TechnicianDashboardData>(
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
            final technician = data.technician;
            final incoming = data.orders
                .where((item) => item.status == 'waiting_confirmation')
                .toList();
            final inProgress = data.orders
                .where(
                  (item) =>
                      item.status != 'waiting_confirmation' &&
                      item.status != 'completed' &&
                      item.status != 'rejected' &&
                      item.status != 'price_rejected',
                )
                .toList();
            final weeklyIncome = data.orders
                .where((item) => item.status == 'completed')
                .fold<double>(
                  0,
                  (sum, item) =>
                      sum +
                      (item.finalTotal > 0
                          ? item.finalTotal
                          : item.estimatedTotal),
                );
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  const _TechnicianBrandHeader(),
                  const SizedBox(height: 22),
                  _GreetingCard(
                    profile: widget.profile,
                    technician: technician,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel(
                    icon: Icons.dashboard_rounded,
                    title: 'Ringkasan',
                  ),
                  const SizedBox(height: 10),
                  _StatsGrid(
                    newOrders: incoming.length,
                    inProgress: inProgress.length,
                    income: weeklyIncome,
                    rating: technician?.rating ?? 0,
                    reviewCount: technician?.completedJobs ?? 0,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _SectionLabel(
                          icon: Icons.assignment_rounded,
                          title: 'Pesanan Masuk',
                          trailing: data.orders.isEmpty
                              ? null
                              : '${data.orders.length}',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Refresh'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
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
                    for (final order in data.orders.take(6)) ...[
                      _TechnicianOrderCard(
                        order: order,
                        onStatus: (status) async {
                          await widget.repo.updateOrderStatus(order.id, status);
                          _refresh();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TechnicianBrandHeader extends StatelessWidget {
  const _TechnicianBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoMark(size: 66),
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
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Solusi Cepat, Hasil Tepat',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            const _SquareIcon(icon: Icons.notifications_none_rounded),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3030),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.profile, required this.technician});

  final AppProfile profile;
  final TechnicianSummary? technician;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4F8FE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      backgroundImage:
                          profile.profileImageUrl == null ||
                              profile.profileImageUrl!.isEmpty
                          ? null
                          : NetworkImage(profile.profileImageUrl!),
                      child:
                          profile.profileImageUrl == null ||
                              profile.profileImageUrl!.isEmpty
                          ? Text(
                              _initials(profile.fullName),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 1,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${profile.fullName.isEmpty ? 'Teknisi' : profile.fullName}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Semangat bekerja hari ini!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    technician?.serviceArea ?? 'Solo, Jawa Tengah',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const Text(
                  'Ubah',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.newOrders,
    required this.inProgress,
    required this.income,
    required this.rating,
    required this.reviewCount,
  });

  final int newOrders;
  final int inProgress;
  final double income;
  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.assignment_rounded,
                color: AppColors.primary,
                badge: '$newOrders',
                title: 'Order Baru',
                value: '$newOrders',
                caption: 'Perlu ditangani',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.build_rounded,
                color: const Color(0xFFFFA726),
                badge: '$inProgress',
                title: 'Sedang Dikerjakan',
                value: '$inProgress',
                caption: 'Dalam proses',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.success,
                title: 'Pendapatan',
                value: formatRupiah(income),
                caption: 'Minggu ini',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                color: const Color(0xFFFFB31A),
                title: 'Rating',
                value: rating <= 0 ? '0.0' : rating.toStringAsFixed(1),
                caption: 'Dari $reviewCount ulasan',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.caption,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String caption;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _techCardDecoration(radius: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              if (badge != null)
                Positioned(
                  right: -8,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 20),
                    child: Text(
                      badge!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _TechnicianOrderCard extends StatelessWidget {
  const _TechnicianOrderCard({required this.order, required this.onStatus});

  final OrderSummary order;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final canAccept = order.status == 'waiting_confirmation';
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _techCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(
                label: orderStatusLabel(order.status),
                color: orderStatusColor(order.status),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _relativeTime(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEAF4FF),
                      AppColors.primary.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryIcon(order.problemDescription),
                  color: AppColors.primary,
                  size: 34,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _OrderMeta(
                      icon: Icons.location_on_rounded,
                      text: [
                        order.address,
                        order.city,
                      ].where((item) => (item ?? '').isNotEmpty).join(', '),
                    ),
                    _OrderMeta(
                      icon: Icons.person_outline_rounded,
                      text: [
                        order.customerName,
                        order.customerPhone,
                      ].where((item) => (item ?? '').isNotEmpty).join(' - '),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Estimasi ${_durationFor(order.problemDescription)}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEF3FA)),
          const SizedBox(height: 14),
          if (canAccept)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onStatus('rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: Color(0xFFF3D6D6)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F8FE0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: () => onStatus('accepted'),
                      child: const Text(
                        'Terima',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _nextStatus(order.status) == order.status
                    ? null
                    : () => onStatus(_nextStatus(order.status)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  'Ubah ke ${orderStatusLabel(_nextStatus(order.status))}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  const _OrderMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 17),
          const SizedBox(width: 5),
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

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4ECF6)),
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

class _TechnicianDashboardData {
  const _TechnicianDashboardData({
    required this.technician,
    required this.orders,
  });

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

String _durationFor(String text) {
  final value = text.toLowerCase();
  if (value.contains('cctv')) return '2 - 4 jam';
  if (value.contains('ac')) return '2 - 3 jam';
  return '1 - 2 jam';
}

String _relativeTime(DateTime? value) {
  if (value == null) return 'Baru saja';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes.clamp(1, 59)} menit yang lalu';
  }
  if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
  return '${diff.inDays} hari yang lalu';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'T';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

BoxDecoration _techCardDecoration({required double radius}) {
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
