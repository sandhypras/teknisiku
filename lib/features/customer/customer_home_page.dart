import 'package:flutter/material.dart';

import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'technician_detail_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    required this.profile,
    required this.repo,
    super.key,
  });

  final AppProfile profile;
  final MarketplaceRepository repo;

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

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_CustomerHomeData>(
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
          final activeOrders = data.orders
              .where((item) => item.status != 'completed')
              .length;
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
                _CustomerHeader(name: widget.profile.fullName),
                const SizedBox(height: 28),
                Text(
                  'Halo, ${_firstName(widget.profile.fullName)}!',
                  style: const TextStyle(
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
                    child: EmptyState(message: 'Belum ada teknisi yang cocok'),
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
                _OrderPrompt(activeOrders: activeOrders),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.name});

  final String name;

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
        Container(
          width: 58,
          height: 58,
          decoration: _softDecoration(radius: 20),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0D58BE),
              size: 28,
            ),
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryIcon(category.name),
                color: const Color(0xFF1269D3),
                size: 42,
              ),
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
                _categorySubtitle(category.name),
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

class _TechnicianStrip extends StatelessWidget {
  const _TechnicianStrip({required this.technicians, required this.onTap});

  final List<TechnicianSummary> technicians;
  final ValueChanged<TechnicianSummary> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
      width: 205,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: _softDecoration(radius: 16),
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
                          decoration: const BoxDecoration(
                            color: Color(0xFFE3EEF9),
                            shape: BoxShape.circle,
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
                    color: const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    technician.serviceArea,
                    style: const TextStyle(
                      color: Color(0xFF0964CC),
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
                    Text(
                      technician.completedJobs > 0 ? 'Rp75.000' : 'Rp100.000',
                      style: const TextStyle(
                        color: Color(0xFF006FE6),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
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

class _OrderPrompt extends StatelessWidget {
  const _OrderPrompt({required this.activeOrders});

  final int activeOrders;

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
            child: const Icon(Icons.assignment_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pesanan aktif',
                  style: TextStyle(
                    color: Color(0xFF07143D),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  activeOrders == 0
                      ? 'Belum ada pesanan aktif. Pilih teknisi untuk mulai memesan.'
                      : '$activeOrders pesanan sedang berjalan. Pantau statusnya di menu Pesanan.',
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
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF0876ED)),
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

String _firstName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Selamat Datang';
  return trimmed.split(RegExp(r'\s+')).first;
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
