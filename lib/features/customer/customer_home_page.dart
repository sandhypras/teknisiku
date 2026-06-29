import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/location_service.dart';
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
  ServiceCategory? _selectedCategory;

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
    final categoriesFuture = widget.repo.categories();
    final ordersFuture = widget.repo.customerOrders();
    final addresses = await widget.repo.customerAddresses();
    final primaryAddress =
        addresses.where((item) => item.isPrimary).firstOrNull ??
        addresses.firstOrNull;
    double? latitude = primaryAddress?.latitude;
    double? longitude = primaryAddress?.longitude;
    var locationLabel = primaryAddress?.city;
    if (latitude == null || longitude == null) {
      try {
        final current = await getCurrentAddress();
        latitude = current.latitude;
        longitude = current.longitude;
        locationLabel = current.city;
      } catch (_) {
        latitude = null;
        longitude = null;
      }
    }
    final results = await Future.wait([
      categoriesFuture,
      widget.repo.technicians(latitude: latitude, longitude: longitude),
      ordersFuture,
      widget.repo.services(),
    ]);
    return _CustomerHomeData(
      categories: results[0] as List<ServiceCategory>,
      technicians: results[1] as List<TechnicianSummary>,
      orders: results[2] as List<OrderSummary>,
      services: results[3] as List<TechnicianService>,
      hasDetectedLocation: latitude != null && longitude != null,
      locationLabel: locationLabel,
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
          colors: [Color(0xFFEAF3FF), Color(0xFFFAFCFF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.28, 0.5],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<_CustomerHomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState();
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
            final latestActiveOrder = activeOrderItems.isEmpty
                ? null
                : activeOrderItems.first;
            final selectedCategory = _selectedCategory;
            final categoryTechnicianIds = selectedCategory == null
                ? null
                : data.services
                      .where((item) => item.categoryId == selectedCategory.id)
                      .map((item) => item.technicianId)
                      .toSet();
            final normalized = _query.toLowerCase();
            final technicians = data.technicians.where((item) {
              final matchesCategory =
                  categoryTechnicianIds == null ||
                  categoryTechnicianIds.contains(item.id);
              final matchesQuery =
                  normalized.isEmpty ||
                  item.name.toLowerCase().contains(normalized) ||
                  item.skills.join(' ').toLowerCase().contains(normalized);
              return matchesCategory && matchesQuery;
            }).toList();

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  const _CustomerBrandHeader(),
                  const SizedBox(height: 18),
                  _FadeSlideIn(
                    index: 0,
                    child: _SearchLocationBar(
                      controller: _searchController,
                      locationLabel: data.locationLabel,
                      detected: data.hasDetectedLocation,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FadeSlideIn(
                    index: 1,
                    child: _ActiveOrderPanel(
                      order: latestActiveOrder,
                      onTap: widget.onGoToOrders,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FadeSlideIn(
                    index: 2,
                    child: _SectionLabel(
                      icon: Icons.home_repair_service_rounded,
                      title: 'Kategori Layanan',
                      trailing: '${data.categories.length}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FadeSlideIn(
                    index: 3,
                    child: _CategoryGrid(
                      categories: data.categories,
                      selected: _selectedCategory,
                      onTap: (category) => setState(() {
                        _selectedCategory = _selectedCategory?.id == category.id
                            ? null
                            : category;
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FadeSlideIn(
                    index: 4,
                    child: _SectionLabel(
                      icon: Icons.engineering_rounded,
                      title: selectedCategory == null
                          ? 'Teknisi Terdekat'
                          : 'Teknisi ${selectedCategory.name} Terdekat',
                      trailing: data.hasDetectedLocation
                          ? data.locationLabel ?? 'Terdekat'
                          : '${technicians.length}',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (technicians.isEmpty)
                    SizedBox(
                      height: 170,
                      child: EmptyState(
                        message: selectedCategory == null
                            ? 'Belum ada teknisi yang cocok'
                            : 'Belum ada teknisi pada kategori ini',
                      ),
                    )
                  else
                    _FadeSlideIn(
                      index: 5,
                      child: _TechnicianStrip(
                        technicians: technicians,
                        onTap: (technician) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TechnicianDetailPage(
                              technicianId: technician.id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  _FadeSlideIn(index: 6, child: const _PromoBanner()),
                  const SizedBox(height: 22),
                  _FadeSlideIn(
                    index: 7,
                    child: _SectionLabel(
                      icon: Icons.receipt_long_rounded,
                      title: 'Pesanan Terbaru',
                      trailing: '${data.orders.length}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.orders.isEmpty)
                    const SizedBox(
                      height: 180,
                      child: EmptyState(message: 'Belum ada pesanan'),
                    )
                  else
                    for (final entry in data.orders.take(3).indexed) ...[
                      _FadeSlideIn(
                        index: 8 + entry.$1,
                        child: _CustomerOrderPreview(order: entry.$2),
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

/// Skeleton-style loading state — terasa lebih hidup daripada spinner polos.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const _CustomerBrandHeader(),
        const SizedBox(height: 20),
        const _ShimmerBlock(height: 58, radius: 18),
        const SizedBox(height: 20),
        const _ShimmerBlock(height: 84, radius: 20),
        const SizedBox(height: 28),
        const _ShimmerBlock(height: 24, width: 180, radius: 8),
        const SizedBox(height: 14),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 12),
                child: const _ShimmerBlock(height: 128, radius: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _ShimmerBlock(height: 24, width: 180, radius: 8),
        const SizedBox(height: 14),
        const _ShimmerBlock(height: 204, radius: 20),
      ],
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height, this.width, this.radius = 16});

  final double height;
  final double? width;
  final double radius;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 3, 0),
              end: Alignment(1 + t * 3, 0),
              colors: const [
                Color(0xFFEAF0F8),
                Color(0xFFF8FAFD),
                Color(0xFFEAF0F8),
              ],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// Fade + slide-up sederhana untuk setiap blok section saat halaman dibuka.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, required this.index});

  final Widget child;
  final int index;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * math.min(widget.index, 8));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _CustomerBrandHeader extends StatelessWidget {
  const _CustomerBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BouncyLogo(),
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
        const _NotificationButton(),
      ],
    );
  }
}

/// Logo dengan animasi "pop" kecil saat halaman dibuka — murni dekoratif.
class _BouncyLogo extends StatefulWidget {
  const _BouncyLogo();

  @override
  State<_BouncyLogo> createState() => _BouncyLogoState();
}

class _BouncyLogoState extends State<_BouncyLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: const AppLogoMark(size: 66));
  }
}

class _NotificationButton extends StatefulWidget {
  const _NotificationButton();

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const _SquareIcon(icon: Icons.notifications_none_rounded),
            Positioned(
              right: 8,
              top: 8,
              child: _PulsingDot(color: const Color(0xFFFF3030)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titik notifikasi yang berdenyut halus agar ikon lonceng terasa "hidup".
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = 0.85 + (_controller.value * 0.3);
        return Transform.scale(
          scale: t,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.55),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.16),
                AppColors.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 22,
                height: 3.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
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

class _ActiveOrderPanel extends StatelessWidget {
  const _ActiveOrderPanel({required this.order, required this.onTap});

  final OrderSummary? order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final order = this.order;
    final accent = order == null
        ? AppColors.primary
        : orderStatusColor(order.status);

    return _PressableScale(
      onTap: onTap,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EEF7)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.16),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.18),
                    accent.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                order == null
                    ? Icons.add_task_rounded
                    : Icons.assignment_turned_in_rounded,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          order == null
                              ? 'Belum ada pesanan aktif'
                              : 'Pesanan aktif',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (order != null) ...[
                        const SizedBox(width: 8),
                        StatusPill(
                          label: orderStatusLabel(order.status),
                          color: accent,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    order == null
                        ? 'Pilih layanan dan teknisi untuk mulai memesan.'
                        : 'Bersama ${order.technicianName}',
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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_right_rounded, color: accent, size: 20),
            ),
          ],
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

class _SearchLocationBar extends StatefulWidget {
  const _SearchLocationBar({
    required this.controller,
    required this.locationLabel,
    required this.detected,
  });

  final TextEditingController controller;
  final String? locationLabel;
  final bool detected;

  @override
  State<_SearchLocationBar> createState() => _SearchLocationBarState();
}

class _SearchLocationBarState extends State<_SearchLocationBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _focused ? AppColors.primary : const Color(0xFFE7EEF7),
                width: _focused ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (_focused ? AppColors.primary : const Color(0xFF234D79))
                          .withValues(alpha: _focused ? 0.16 : 0.08),
                  blurRadius: _focused ? 20 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Focus(
              onFocusChange: (value) => setState(() => _focused = value),
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: 'Cari layanan atau masalah...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF7B8498),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _focused
                        ? AppColors.primary
                        : const Color(0xFF68758F),
                    size: 28,
                  ),
                  suffixIcon: widget.controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF98A3B8),
                            size: 20,
                          ),
                          onPressed: () => widget.controller.clear(),
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: _PressableScale(
            borderRadius: 18,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: _softDecoration(radius: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: widget.detected
                        ? const Color(0xFF1269D3)
                        : const Color(0xFF9AA8C2),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.detected)
                          const Text(
                            'Lokasi Saat Ini',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF6A8AB8),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        Text(
                          widget.detected
                              ? (widget.locationLabel?.trim().isNotEmpty == true
                                    ? widget.locationLabel!.trim()
                                    : 'Lokasi saya')
                              : 'Lokasi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF143677),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF1269D3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onTap,
  });

  final List<ServiceCategory> categories;
  final ServiceCategory? selected;
  final ValueChanged<ServiceCategory> onTap;

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
        final selectedCategory = selected?.id == category.id;
        return _PressableScale(
          onTap: () => onTap(category),
          borderRadius: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selectedCategory
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selectedCategory
                    ? AppColors.primary
                    : const Color(0xFFE7EEF7),
                width: selectedCategory ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (selectedCategory
                              ? AppColors.primary
                              : const Color(0xFF234D79))
                          .withValues(alpha: selectedCategory ? 0.16 : 0.08),
                  blurRadius: selectedCategory ? 20 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CategoryIcon(category: category, active: selectedCategory),
                const SizedBox(height: 10),
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selectedCategory
                        ? AppColors.primary
                        : const Color(0xFF07143D),
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
          ),
        );
      },
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category, this.active = false});

  final ServiceCategory category;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.iconUrl;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? [
                  AppColors.primary.withValues(alpha: 0.20),
                  const Color(0xFFFFF0DA),
                ]
              : const [Color(0xFFEAF4FF), Color(0xFFFFF4E7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: active
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.35))
            : null,
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
      height: 212,
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
    final isNew = technician.rating == 0;
    final rating = isNew ? 'Baru' : technician.rating.toStringAsFixed(1);
    final mainSkill = technician.skills.isEmpty
        ? 'Spesialis Teknisi'
        : 'Spesialis ${technician.skills.take(2).join(' & ')}';
    final distance = technician.distanceKm;
    return SizedBox(
      width: 220,
      child: _PressableScale(
        onTap: onTap,
        borderRadius: 20,
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.18),
                              AppColors.primary.withValues(alpha: 0.06),
                            ],
                          ),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isNew
                                    ? const Color(0xFFEFF3F9)
                                    : const Color(0xFFFFF6E0),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isNew
                                        ? Icons.auto_awesome_rounded
                                        : Icons.star_rounded,
                                    color: isNew
                                        ? const Color(0xFF6A748B)
                                        : const Color(0xFFFFB20E),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      color: Color(0xFF07143D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
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
              Row(
                children: [
                  if (distance != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Container(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9B5A12),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 18, color: Color(0xFFE1E8F0)),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lihat profil teknisi',
                      style: TextStyle(
                        color: Color(0xFF59657C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 136,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF075AC8), Color(0xFF0986F6)],
          ),
        ),
        child: Stack(
          children: [
            // Pola dekoratif lingkaran transparan untuk kedalaman visual.
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 36,
              bottom: -36,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
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
                    child: Image.asset(
                      'assets/logos/logoku.png',
                      fit: BoxFit.contain,
                    ),
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
            ),
          ],
        ),
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
    final accent = orderStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: orderStatusLabel(order.status), color: accent),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: accent),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Pantau progres pesanan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
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

/// Wrapper interaktif: mengecilkan child sedikit saat ditekan untuk feedback
/// taktil tanpa mengubah perilaku tap/onTap aslinya.
class _PressableScale extends StatefulWidget {
  const _PressableScale({
    required this.child,
    this.onTap,
    this.borderRadius = 16,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
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

String _shortTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}

class _CustomerHomeData {
  const _CustomerHomeData({
    required this.categories,
    required this.technicians,
    required this.orders,
    required this.services,
    required this.hasDetectedLocation,
    this.locationLabel,
  });

  final List<ServiceCategory> categories;
  final List<TechnicianSummary> technicians;
  final List<OrderSummary> orders;
  final List<TechnicianService> services;
  final bool hasDetectedLocation;
  final String? locationLabel;
}
