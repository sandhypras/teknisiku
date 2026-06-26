import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app.dart';
import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'order_form_page.dart';

class TechnicianDetailPage extends StatefulWidget {
  const TechnicianDetailPage({required this.technicianId, super.key});

  final String technicianId;

  @override
  State<TechnicianDetailPage> createState() => _TechnicianDetailPageState();
}

class _TechnicianDetailPageState extends State<TechnicianDetailPage> {
  late final MarketplaceRepository _repo;
  late Future<_TechnicianDetailData> _future;
  final Set<String> _selectedServiceIds = {};
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _repo = MarketplaceRepository(Supabase.instance.client);
    _future = _load();
  }

  Future<_TechnicianDetailData> _load() async {
    final results = await Future.wait([
      _repo.technician(widget.technicianId),
      _repo.services(technicianId: widget.technicianId),
    ]);
    return _TechnicianDetailData(
      technician: results[0] as TechnicianSummary,
      services: results[1] as List<TechnicianService>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: FutureBuilder<_TechnicianDetailData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {
                  _future = _load();
                }),
              );
            }
            final data = snapshot.data!;
            final selected = data.services
                .where((item) => _selectedServiceIds.contains(item.id))
                .toList();
            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _DetailHero(technician: data.technician),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabsHeaderDelegate(
                        tab: _tab,
                        onChanged: (value) => setState(() => _tab = value),
                        reviewCount: data.technician.completedJobs,
                      ),
                    ),
                    if (_tab == 0)
                      _ServicesSliver(
                        services: data.services,
                        selectedIds: _selectedServiceIds,
                        onTap: (service) => setState(() {
                          if (_selectedServiceIds.contains(service.id)) {
                            _selectedServiceIds.remove(service.id);
                          } else {
                            _selectedServiceIds.add(service.id);
                          }
                        }),
                      )
                    else if (_tab == 1)
                      SliverToBoxAdapter(
                        child: _ReviewsPanel(technician: data.technician),
                      )
                    else
                      SliverToBoxAdapter(
                        child: _ProfilePanel(technician: data.technician),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 106)),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _BookingBar(
                    selected: selected,
                    onPressed: selected.isEmpty
                        ? null
                        : () {
                            if (Supabase.instance.client.auth.currentUser ==
                                null) {
                              Navigator.pushNamed(context, AppRoutes.login);
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderFormPage(
                                  technician: data.technician,
                                  services: selected,
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.technician});

  final TechnicianSummary technician;

  @override
  Widget build(BuildContext context) {
    final skill = technician.skills.isEmpty
        ? 'Spesialis Perbaikan Perangkat'
        : 'Spesialis ${technician.skills.take(2).join(' & ')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: Column(
        children: [
          Row(
            children: [
              _SoftIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              Row(
                children: [
                  const AppLogoMark(size: 54),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Si Teknisi',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Solusi Cepat, Hasil Tepat',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              _SoftIconButton(icon: Icons.notifications_none_rounded),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF234D79,
                          ).withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF4FF),
                      child: Text(
                        _initials(technician.name),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 5,
                    bottom: 12,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB31A),
                          size: 28,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${technician.rating <= 0 ? 4.9 : technician.rating.toStringAsFixed(1)} (${technician.completedJobs} ulasan)',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon(skill), color: AppColors.primary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              skill,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _HeroFact(
                  icon: Icons.verified_user_outlined,
                  title: 'Terverifikasi',
                ),
              ),
              Expanded(
                child: _HeroFact(
                  icon: Icons.schedule_rounded,
                  title: 'Respon Cepat\n+/- 15 menit',
                ),
              ),
              Expanded(
                child: _HeroFact(
                  icon: Icons.location_on_outlined,
                  title: 'Area Layanan\n${technician.serviceArea}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFact extends StatelessWidget {
  const _HeroFact({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 25),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TabsHeaderDelegate({
    required this.tab,
    required this.onChanged,
    required this.reviewCount,
  });

  final int tab;
  final ValueChanged<int> onChanged;
  final int reviewCount;

  @override
  double get minExtent => 82;

  @override
  double get maxExtent => 82;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x120A2F5F),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Layanan',
            selected: tab == 0,
            onTap: () => onChanged(0),
          ),
          _TabButton(
            label: 'Ulasan ($reviewCount)',
            selected: tab == 1,
            onTap: () => onChanged(1),
          ),
          _TabButton(
            label: 'Profil',
            selected: tab == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) {
    return tab != oldDelegate.tab || reviewCount != oldDelegate.reviewCount;
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                ),
              ),
              Positioned(
                bottom: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 104 : 0,
                  height: 4,
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
    );
  }
}

class _ServicesSliver extends StatelessWidget {
  const _ServicesSliver({
    required this.services,
    required this.selectedIds,
    required this.onTap,
  });

  final List<TechnicianService> services;
  final Set<String> selectedIds;
  final ValueChanged<TechnicianService> onTap;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 260,
          child: EmptyState(message: 'Teknisi belum punya layanan approved'),
        ),
      );
    }
    return SliverList.builder(
      itemCount: services.length + 1,
      itemBuilder: (context, index) {
        if (index == services.length) {
          return const _WarrantyCard();
        }
        final service = services[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(20, index == 0 ? 16 : 0, 20, 14),
          child: _ServiceDetailCard(
            service: service,
            selected: selectedIds.contains(service.id),
            onTap: () => onTap(service),
          ),
        );
      },
    );
  }
}

class _ServiceDetailCard extends StatelessWidget {
  const _ServiceDetailCard({
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final TechnicianService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE3ECF6),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF234D79).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  categoryIcon(service.categoryName ?? service.name),
                  color: AppColors.primary,
                  size: 52,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      service.description?.isNotEmpty == true
                          ? service.description!
                          : service.categoryName ?? 'Layanan teknisi',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mulai dari\n${formatRupiah(service.price)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Estimasi\n${service.duration ?? '1-2 hari'}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
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
        ),
      ),
    );
  }
}

class _WarrantyCard extends StatelessWidget {
  const _WarrantyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5E8FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garansi Pekerjaan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Semua pekerjaan bergaransi hingga 30 hari setelah layanan selesai.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.35,
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

class _ReviewsPanel extends StatelessWidget {
  const _ReviewsPanel({required this.technician});

  final TechnicianSummary technician;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _detailCardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFB31A)),
                const SizedBox(width: 8),
                Text(
                  '${technician.rating <= 0 ? 4.9 : technician.rating.toStringAsFixed(1)} dari ${technician.completedJobs} ulasan',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Ulasan pelanggan akan tampil di sini setelah order selesai dan pelanggan memberi rating.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.technician});

  final TechnicianSummary technician;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _detailCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tentang Teknisi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              technician.description?.isNotEmpty == true
                  ? technician.description!
                  : 'Teknisi siap membantu kebutuhan perbaikan perangkat Anda.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: technician.skills
                  .map(
                    (skill) =>
                        StatusPill(label: skill, color: AppColors.primary),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.selected, required this.onPressed});

  final List<TechnicianService> selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final total = selected.fold<double>(0, (sum, item) => sum + item.price);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(
            selected.isEmpty
                ? 'Pilih Layanan'
                : 'Pesan Teknisi - ${formatRupiah(total)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  const _SoftIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234D79).withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}

class _TechnicianDetailData {
  const _TechnicianDetailData({
    required this.technician,
    required this.services,
  });

  final TechnicianSummary technician;
  final List<TechnicianService> services;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'T';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

BoxDecoration _detailCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE3ECF6)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
