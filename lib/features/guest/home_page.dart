import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../customer/technician_detail_page.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  late final MarketplaceRepository _repo;
  late Future<_GuestHomeData> _future;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _repo = MarketplaceRepository(Supabase.instance.client);
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

  Future<_GuestHomeData> _load() async {
    final results = await Future.wait([
      _repo.categories(),
      _repo.technicians(),
    ]);
    return _GuestHomeData(
      categories: results[0] as List<ServiceCategory>,
      technicians: results[1] as List<TechnicianSummary>,
    );
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_GuestHomeData>(
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
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: 28),
                  const Text(
                    'Halo, Selamat Datang!',
                    style: TextStyle(
                      color: Color(0xFF07143D),
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Butuh bantuan teknisi? Kami siap membantumu.',
                    style: TextStyle(
                      color: Color(0xFF51607A),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SearchLocationBar(controller: _searchController),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Kategori Layanan',
                    actionLabel: 'Lihat semua',
                    onAction: _refresh,
                  ),
                  const SizedBox(height: 14),
                  _CategoryGrid(categories: data.categories),
                  const SizedBox(height: 26),
                  _SectionTitle(
                    title: 'Teknisi Terdekat',
                    actionLabel: 'Lihat semua',
                    onAction: _refresh,
                  ),
                  const SizedBox(height: 14),
                  if (technicians.isEmpty)
                    const SizedBox(
                      height: 170,
                      child: EmptyState(
                        message: 'Belum ada teknisi yang cocok',
                        icon: Icons.engineering_outlined,
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
                  const _LoginPrompt(),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const _GuestBottomNav(),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Color(0xFF1269D3),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset('assets/logos/logoku.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Si Teknisi',
                style: TextStyle(
                  color: Color(0xFF0964CC),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Solusi Cepat, Hasil Tepat',
                style: TextStyle(
                  color: Color(0xFF0964CC),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _SoftIconButton(
          icon: Icons.notifications_none_rounded,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
      ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF07143D),
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF006FE6),
              fontWeight: FontWeight.w900,
            ),
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
            return Container(
              decoration: _softDecoration(radius: 16),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8,
                vertical: compact ? 9 : 11,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CategoryIcon(category: category, compact: compact),
                  SizedBox(height: compact ? 8 : 10),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF07143D),
                      fontSize: compact ? 12.5 : 14,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      _categorySubtitle(category.name),
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
            );
          },
        );
      },
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category, this.compact = false});

  final ServiceCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.iconUrl;
    return Container(
      width: compact ? 46 : 52,
      height: compact ? 46 : 52,
      padding: EdgeInsets.all(iconUrl == null || iconUrl.isEmpty ? 8 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl == null || iconUrl.isEmpty
          ? Icon(
              categoryIcon(category.name),
              color: const Color(0xFF1269D3),
              size: compact ? 32 : 36,
            )
          : Image.network(
              iconUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                categoryIcon(category.name),
                color: const Color(0xFF1269D3),
                size: compact ? 32 : 36,
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
      height: 162,
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
    final imageUrl = technician.profileImageUrl;
    final skill = technician.skills.isEmpty
        ? 'Spesialis Teknisi'
        : 'Spesialis ${technician.skills.take(2).join(' & ')}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 156,
          decoration: _softDecoration(radius: 18),
          padding: const EdgeInsets.all(13),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEAF4FF),
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
                        clipBehavior: Clip.antiAlias,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.engineering_rounded,
                                  color: Color(0xFF1269D3),
                                  size: 32,
                                ),
                              )
                            : const Icon(
                                Icons.engineering_rounded,
                                color: Color(0xFF1269D3),
                                size: 32,
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
                  Text(
                    technician.serviceArea,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF1269D3),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF0876ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login atau Daftar sebelum memesan',
                  style: TextStyle(
                    color: Color(0xFF07143D),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Nikmati pemesanan lebih cepat dan riwayat layanan.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0876ED),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login / Daftar'),
                SizedBox(width: 5),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBottomNav extends StatelessWidget {
  const _GuestBottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEAF4FF),
      onDestinationSelected: (index) {
        if (index != 0) Navigator.pushNamed(context, AppRoutes.login);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF0876ED)),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Layanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'Pesanan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _SoftIconButton extends StatelessWidget {
  const _SoftIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: _softDecoration(radius: 20),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF0D58BE), size: 28),
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

class _GuestHomeData {
  const _GuestHomeData({required this.categories, required this.technicians});

  final List<ServiceCategory> categories;
  final List<TechnicianSummary> technicians;
}
