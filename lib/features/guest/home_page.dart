import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app.dart';
import '../../app/theme.dart';
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

  @override
  void initState() {
    super.initState();
    _repo = MarketplaceRepository(Supabase.instance.client);
    _future = _load();
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

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Row(
                    children: [
                      const AppLogoMark(size: 46),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Si Teknisi',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Marketplace teknisi wilayah Solo',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.login),
                        icon: const Icon(Icons.login_rounded),
                        tooltip: 'Masuk',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _GuestHero(),
                  const SizedBox(height: 22),
                  MobileSectionHeader(
                    title: 'Kategori layanan',
                    subtitle: '${data.categories.length} kategori aktif',
                  ),
                  const SizedBox(height: 12),
                  _CategoryGrid(categories: data.categories),
                  const SizedBox(height: 24),
                  MobileSectionHeader(
                    title: 'Teknisi tersedia',
                    subtitle: 'Pilih teknisi sendiri sesuai PRD',
                    action: TextButton(
                      onPressed: _refresh,
                      child: const Text('Refresh'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.technicians.isEmpty)
                    const SizedBox(
                      height: 220,
                      child: EmptyState(
                        message: 'Belum ada teknisi verified',
                        icon: Icons.engineering_outlined,
                      ),
                    )
                  else
                    for (final technician in data.technicians) ...[
                      _TechnicianCard(
                        technician: technician,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TechnicianDetailPage(
                              technicianId: technician.id,
                            ),
                          ),
                        ),
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

class _GuestHero extends StatelessWidget {
  const _GuestHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Servis komputer, laptop, HP, CCTV, printer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Cari teknisi terpercaya tanpa ribet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Lihat profil, cek estimasi harga, lalu login untuk membuat pesanan.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.registerCustomer),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Daftar Customer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: 'Masuk',
              ),
            ],
          ),
        ],
      ),
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
    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryIcon(category.name),
                color: AppColors.secondary,
                size: 28,
              ),
              const SizedBox(height: 9),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.technician, required this.onTap});

  final TechnicianSummary technician;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                foregroundColor: AppColors.secondary,
                child: const Icon(Icons.engineering_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${technician.skills.take(2).join(', ')} - ${technician.serviceArea}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          technician.rating == 0
                              ? 'Baru'
                              : technician.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${technician.completedJobs} pekerjaan',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestHomeData {
  const _GuestHomeData({required this.categories, required this.technicians});

  final List<ServiceCategory> categories;
  final List<TechnicianSummary> technicians;
}
