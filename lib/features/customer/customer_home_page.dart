import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'technician_detail_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    required this.profile,
    required this.repo,
    this.onGoToOrders,
    super.key,
  });

  final AppProfile profile;
  final MarketplaceRepository repo;
  final VoidCallback? onGoToOrders;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  late Future<_CustomerHomeData> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_CustomerHomeData> _load() async {
    final results = await Future.wait([
      widget.repo.categories(),
      widget.repo.technicians(),
      widget.repo.customerOrders(),
    ]);
    return _CustomerHomeData(
      categories: results[0] as List<ServiceCategory>,
      technicians: results[1] as List<TechnicianSummary>,
      orders: results[2] as List<OrderSummary>,
    );
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
        bottom: false,
        child: FutureBuilder<_CustomerHomeData>(
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
            final activeOrderItems = data.orders
                .where((item) => item.status != 'completed')
                .toList();
            final activeOrders = activeOrderItems.length;
            final latestActiveOrder = activeOrderItems.isEmpty
                ? null
                : activeOrderItems.first;
            final normalized = _query.toLowerCase();
            final technicians = normalized.isEmpty
                ? data.technicians
                : data.technicians
                      .where(
                        (item) =>
                            item.name.toLowerCase().contains(normalized) ||
                            item.skills
                                .join(' ')
                                .toLowerCase()
                                .contains(normalized),
                      )
                      .toList();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  const _CustomerBrandHeader(),
                  const SizedBox(height: 18),
                  _CustomerHero(
                    profile: widget.profile,
                    activeOrders: activeOrders,
                    onOrderTap: widget.onGoToOrders,
                  ),
                  const SizedBox(height: 16),
                  _QuickActionRow(
                    categories: data.categories.length,
                    technicians: data.technicians.length,
                    activeOrders: activeOrders,
                    onOrdersTap: widget.onGoToOrders,
                  ),
                  const SizedBox(height: 18),
                  _SearchLocationBar(controller: _searchController),
                  const SizedBox(height: 20),
                  _ActiveOrderPanel(
                    order: latestActiveOrder,
                    onTap: widget.onGoToOrders,
                  ),
                  const SizedBox(height: 26),
                  _SectionLabel(
                    icon: Icons.home_repair_service_rounded,
                    title: 'Kategori Layanan',
                    trailing: '${data.categories.length}',
                  ),
                  const SizedBox(height: 14),
                  _CategoryGrid(categories: data.categories),
                  const SizedBox(height: 26),
                  _SectionLabel(
                    icon: Icons.engineering_rounded,
                    title: 'Teknisi Terdekat',
                    trailing: '${technicians.length}',
                  ),
                  const SizedBox(height: 14),
                  if (technicians.isEmpty)
                    const SizedBox(
                      height: 170,
                      child: EmptyState(
                        message: 'Belum ada teknisi yang cocok',
                      ),
                    )
                  else
                    _TechnicianStrip(
                      technicians: technicians,
                      onTap: (technician) => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TechnicianDetailPage(technicianId: technician.id),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const _PromoBanner(),
                  const SizedBox(height: 20),
                  _SectionLabel(
                    icon: Icons.receipt_long_rounded,
                    title: 'Pesanan Terbaru',
                    trailing: '${data.orders.length}',
                  ),
                  const SizedBox(height: 12),
                  if (data.orders.isEmpty)
                    const SizedBox(
                      height: 180,
                      child: EmptyState(message: 'Belum ada pesanan'),
                    )
                  else
                    for (final order in data.orders.take(3)) ...[
                      _CustomerOrderPreview(order: order),
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

class _CustomerBrandHeader extends StatelessWidget {
  const _CustomerBrandHeader();

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
                  letterSpacing: 0,
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
            letterSpacing: 0,
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

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({
    required this.profile,
    required this.activeOrders,
    required this.onOrderTap,
  });

  final AppProfile profile;
  final int activeOrders;
  final VoidCallback? onOrderTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4ECF6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                child: Text(
                  _initials(profile.fullName),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${profile.fullName.isEmpty ? 'Customer' : profile.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Mau servis apa hari ini?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF075AC8), Color(0xFF13A3F7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cari teknisi terpercaya di dekatmu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Pilih kategori, cek teknisi, lalu pesan layanan.',
                        style: TextStyle(
                          color: Color(0xFFEAF4FF),
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.home_repair_service_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOrderTap,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: Text(
                    activeOrders == 0 ? 'Mulai Pesan' : 'Lihat Pesanan',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Color(0xFF9B5A12),
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Solo',
                      style: TextStyle(
                        color: Color(0xFF9B5A12),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.categories,
    required this.technicians,
    required this.activeOrders,
    required this.onOrdersTap,
  });

  final int categories;
  final int technicians;
  final int activeOrders;
  final VoidCallback? onOrdersTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionChip(
            icon: Icons.grid_view_rounded,
            label: 'Kategori',
            value: '$categories',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionChip(
            icon: Icons.engineering_rounded,
            label: 'Teknisi',
            value: '$technicians',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionChip(
            icon: Icons.receipt_long_rounded,
            label: 'Pesanan',
            value: '$activeOrders',
            color: const Color(0xFFFFA726),
            onTap: onOrdersTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 94,
          padding: const EdgeInsets.all(12),
          decoration: _softDecoration(radius: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderPanel extends StatelessWidget {
  const _ActiveOrderPanel({required this.order, required this.onTap});

  final OrderSummary? order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final order = this.order;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _softDecoration(radius: 20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      (order == null
                              ? AppColors.primary
                              : orderStatusColor(order.status))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  order == null
                      ? Icons.add_task_rounded
                      : Icons.assignment_turned_in_rounded,
                  color: order == null
                      ? AppColors.primary
                      : orderStatusColor(order.status),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order == null
                          ? 'Belum ada pesanan aktif'
                          : 'Pesanan aktif',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      order == null
                          ? 'Pilih layanan dan teknisi untuk mulai memesan.'
                          : '${orderStatusLabel(order.status)} - ${order.technicianName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
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

class _SearchLocationBar extends StatelessWidget {
  const _SearchLocationBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 58,
            decoration: _softDecoration(radius: 18),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Cari layanan atau masalah...',
                hintStyle: TextStyle(
                  color: Color(0xFF7B8498),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Color(0xFF68758F),
                  size: 30,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: _softDecoration(radius: 18),
          child: const Row(
            children: [
              Icon(Icons.location_on_rounded, color: Color(0xFF1269D3)),
              SizedBox(width: 6),
              Text(
                'Solo',
                style: TextStyle(
                  color: Color(0xFF143677),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1269D3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<ServiceCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 180,
        child: EmptyState(message: 'Belum ada kategori aktif'),
      );
    }
    final visible = categories.take(6).toList();
    return GridView.builder(
      itemCount: visible.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.96,
      ),
      itemBuilder: (context, index) {
        final category = visible[index];
        return Container(
          decoration: _softDecoration(radius: 16),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CategoryIcon(category: category),
              const SizedBox(height: 10),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF07143D),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category.description?.trim().isNotEmpty == true
                    ? category.description!.trim()
                    : _categorySubtitle(category.name),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF59657C),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.iconUrl;
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4FF), Color(0xFFFFF4E7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: iconUrl == null || iconUrl.isEmpty
          ? Icon(
              categoryIcon(category.name),
              color: const Color(0xFF1269D3),
              size: 36,
            )
          : Image.network(
              iconUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                categoryIcon(category.name),
                color: const Color(0xFF1269D3),
                size: 36,
              ),
            ),
    );
  }
}

class _TechnicianStrip extends StatelessWidget {
  const _TechnicianStrip({required this.technicians, required this.onTap});

  final List<TechnicianSummary> technicians;
  final ValueChanged<TechnicianSummary> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 204,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 4),
        itemCount: technicians.take(6).length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final technician = technicians[index];
          return _TechnicianCard(
            technician: technician,
            onTap: () => onTap(technician),
          );
        },
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.technician, required this.onTap});

  final TechnicianSummary technician;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = technician.rating == 0
        ? 'Baru'
        : technician.rating.toStringAsFixed(1);
    final mainSkill = technician.skills.isEmpty
        ? 'Spesialis Teknisi'
        : 'Spesialis ${technician.skills.take(2).join(' & ')}';
    return SizedBox(
      width: 218,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            decoration: _softDecoration(radius: 20),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.engineering_rounded,
                            color: Color(0xFF1269D3),
                            size: 38,
                          ),
                        ),
                        Positioned(
                          right: 1,
                          bottom: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF12B956),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technician.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF07143D),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB20E),
                                size: 18,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                rating,
                                style: const TextStyle(
                                  color: Color(0xFF07143D),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                technician.completedJobs > 0
                                    ? ' (${technician.completedJobs})'
                                    : '',
                                style: const TextStyle(
                                  color: Color(0xFF6A748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mainSkill,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF59657C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    technician.serviceArea,
                    style: const TextStyle(
                      color: Color(0xFF9B5A12),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                const Divider(height: 18, color: Color(0xFFE1E8F0)),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mulai dari',
                        style: TextStyle(
                          color: Color(0xFF59657C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Lihat detail',
                      style: TextStyle(
                        color: Color(0xFF006FE6),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF075AC8), Color(0xFF0986F6)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/logos/logoku.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Solusi Cepat,\nHasil Tepat!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Percayakan perbaikan perangkat Anda kepada teknisi profesional kami.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.home_repair_service_rounded,
            color: Colors.white.withValues(alpha: 0.82),
            size: 72,
          ),
        ],
      ),
    );
  }
}

class _CustomerOrderPreview extends StatelessWidget {
  const _CustomerOrderPreview({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softDecoration(radius: 20),
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
              Text(
                order.orderNumber,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
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
                  size: 32,
                ),
              ),
              const SizedBox(width: 13),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _PreviewMeta(
                      icon: Icons.engineering_outlined,
                      text: 'Teknisi: ${order.technicianName}',
                    ),
                    _PreviewMeta(
                      icon: Icons.calendar_today_outlined,
                      text:
                          '${order.scheduleDate} ${_shortTime(order.scheduleTime)}',
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
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Pantau progres pesanan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewMeta extends StatelessWidget {
  const _PreviewMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _softDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE7EEF7)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _categorySubtitle(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('komputer')) return 'Perbaikan &\nPerawatan';
  if (lower.contains('laptop')) return 'Service &\nUpgrade';
  if (lower.contains('handphone')) return 'Perbaikan\nSemua Merek';
  if (lower.contains('printer')) return 'Perbaikan &\nMaintenance';
  if (lower.contains('cctv')) return 'Instalasi &\nPerbaikan';
  if (lower.contains('jaringan')) return 'Instalasi &\nTroubleshooting';
  return 'Servis &\nPerbaikan';
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'C';
  final first = parts.first.substring(0, 1);
  if (parts.length == 1 || parts.last.isEmpty) return first.toUpperCase();
  return '$first${parts.last.substring(0, 1)}'.toUpperCase();
}

String _shortTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

class _CustomerHomeData {
  const _CustomerHomeData({
    required this.categories,
    required this.technicians,
    required this.orders,
  });

  final List<ServiceCategory> categories;
  final List<TechnicianSummary> technicians;
  final List<OrderSummary> orders;
}
