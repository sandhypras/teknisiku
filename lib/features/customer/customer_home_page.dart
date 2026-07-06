import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/location_service.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../notifications/notifications_page.dart';
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
          colors: [Color(0xFFE3EFFF), Color(0xFFF7FAFF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.3, 0.55],
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
                  const SizedBox(height: 26),
                  const _FadeSlideIn(index: 0, child: _HomeGreeting()),
                  const SizedBox(height: 22),
                  _FadeSlideIn(
                    index: 1,
                    child: _SearchLocationBar(
                      controller: _searchController,
                      locationLabel: data.locationLabel,
                      detected: data.hasDetectedLocation,
                    ),
                  ),
                  if (!data.hasDetectedLocation) ...[
                    const SizedBox(height: 14),
                    const _LocationWarningCard(),
                  ],
                  const SizedBox(height: 26),
                  _FadeSlideIn(
                    index: 2,
                    child: _SectionLabel(
                      icon: Icons.grid_view_rounded,
                      title: 'Kategori Layanan',
                      trailing: 'Lihat semua',
                      onTrailingTap: _refresh,
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
                          : 'Teknisi ${selectedCategory.name}',
                      trailing: 'Lihat semua',
                      onTrailingTap: _refresh,
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
                    child: _OrderShortcut(
                      activeOrder: latestActiveOrder,
                      onTap: widget.onGoToOrders,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton-style loading state.
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

/// Fade + slide-up untuk setiap section saat halaman dibuka.
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

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Halo, Selamat Datang!',
          style: TextStyle(
            color: Color(0xFF07143D),
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Butuh bantuan teknisi? Kami siap membantumu.',
          style: TextStyle(
            color: Color(0xFF51607A),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Label section dengan ikon ber-aksen warna dan garis bawah, plus tombol aksi
/// opsional yang dibungkus chip lembut agar terasa "tappable".
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                AppColors.primary.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
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
                  color: Color(0xFF07143D),
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
          _PressableScale(
            onTap: onTrailingTap,
            borderRadius: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailing!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

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

class _LocationWarningCard extends StatelessWidget {
  const _LocationWarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDCA3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_off_rounded, color: Color(0xFFE58B00)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lokasi belum lengkap. Hasil teknisi terdekat memakai data umum sampai lokasi aktif tersimpan.',
              style: TextStyle(
                color: Color(0xFF6B4A13),
                fontSize: 12,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
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
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        return GridView.builder(
          itemCount: visible.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: compact ? 0.70 : 0.76,
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
                              .withValues(
                                alpha: selectedCategory ? 0.16 : 0.08,
                              ),
                      blurRadius: selectedCategory ? 20 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : 8,
                  vertical: compact ? 9 : 11,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CategoryIcon(
                      category: category,
                      active: selectedCategory,
                      compact: compact,
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selectedCategory
                            ? AppColors.primary
                            : const Color(0xFF07143D),
                        fontSize: compact ? 12.5 : 14,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        category.description?.trim().isNotEmpty == true
                            ? category.description!.trim()
                            : _categorySubtitle(category.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF59657C),
                          fontSize: compact ? 10.5 : 11,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Ikon kategori — sekarang dibungkus dalam lingkaran dengan padding tetap
/// dan `BoxFit.cover` + `ClipOval`, sehingga gambar jaringan apa pun (potret,
/// landscape, persegi) selalu terlihat memenuhi bentuk bulat tanpa terpotong
/// aneh, terdistorsi, atau menyembul keluar dari border.
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.category,
    this.active = false,
    this.compact = false,
  });

  final ServiceCategory category;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.iconUrl;
    final hasImage = iconUrl != null && iconUrl.isNotEmpty;
    final size = compact ? 46.0 : 52.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
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
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white,
          width: active ? 1.4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? ClipOval(
              child: Padding(
                // Sedikit padding agar logo persegi/lonjong tetap "bernapas"
                // di dalam lingkaran, bukan menempel pas di tepi.
                padding: const EdgeInsets.all(6),
                child: Image.network(
                  iconUrl,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => Icon(
                    categoryIcon(category.name),
                    color: const Color(0xFF1269D3),
                    size: compact ? 28 : 32,
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Icon(
                      categoryIcon(category.name),
                      color: const Color(0xFF1269D3),
                      size: compact ? 28 : 32,
                    );
                  },
                ),
              ),
            )
          : Icon(
              categoryIcon(category.name),
              color: const Color(0xFF1269D3),
              size: compact ? 30 : 34,
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
      height: 166,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: technicians.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final technician = technicians[index];
          return SizedBox(
            width: 184,
            child: _TechnicianCard(
              technician: technician,
              onTap: () => onTap(technician),
            ),
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
    final distance = technician.distanceKm;
    final imageUrl = technician.profileImageUrl;
    final skill = technician.skills.isEmpty
        ? 'Spesialis Teknisi'
        : 'Spesialis ${technician.skills.take(2).join(' & ')}';

    return _PressableScale(
      onTap: onTap,
      borderRadius: 18,
      child: Container(
        height: 160,
        decoration: _softDecoration(radius: 18),
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Avatar dibungkus ClipOval terpisah dari border, jadi
                    // foto teknisi selalu mengikuti bentuk bulat dan tidak
                    // pernah mengintip keluar dari ring putih di sekitarnya.
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF234D79,
                            ).withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: const Color(0xFFEAF4FF),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.engineering_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                )
                              : const Icon(
                                  Icons.engineering_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
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
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            isNew
                                ? Icons.auto_awesome_rounded
                                : Icons.star_rounded,
                            color: isNew
                                ? const Color(0xFF6A748B)
                                : const Color(0xFFFFB20E),
                            size: 17,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              isNew
                                  ? 'Baru'
                                  : '$rating (${technician.completedJobs})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF263A63),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              skill,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF59657C),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const Spacer(),
            Container(height: 1, color: const Color(0xFFE4ECF6)),
            const SizedBox(height: 9),
            Row(
              children: [
                const Text(
                  'Area',
                  style: TextStyle(
                    color: Color(0xFF6A748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (distance != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ] else
                  Flexible(
                    child: Text(
                      technician.serviceArea,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner promo dengan dekorasi lingkaran transparan, gradasi lebih kaya,
/// dan logo aplikasi yang dibungkus rapi di dalam chip bundar putih
/// transparan agar tidak pernah terlihat "gepeng" atau melebihi batasnya.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 140,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064DB0), Color(0xFF0B8CFA), Color(0xFF35B0FF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              top: -26,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -44,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -18,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
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
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logos/logoku.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.home_repair_service_rounded,
                          color: Colors.white,
                        ),
                      ),
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
                    color: Colors.white.withValues(alpha: 0.85),
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

class _OrderShortcut extends StatelessWidget {
  const _OrderShortcut({required this.activeOrder, required this.onTap});

  final OrderSummary? activeOrder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasActiveOrder = activeOrder != null;
    return _PressableScale(
      onTap: onTap,
      borderRadius: 18,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _softDecoration(radius: 18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.75),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                hasActiveOrder
                    ? Icons.receipt_long_rounded
                    : Icons.shopping_bag_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasActiveOrder
                        ? 'Pesanan aktif sedang berjalan'
                        : 'Pesan layanan lebih cepat',
                    style: const TextStyle(
                      color: Color(0xFF07143D),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasActiveOrder
                        ? 'Pantau status teknisi dan progres layanan Anda.'
                        : 'Pilih kategori, cek teknisi, lalu pesan layanan.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF59657C),
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Pesanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.white,
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
