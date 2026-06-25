import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'customer_shell_page.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _load();
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
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                CustomerAppBar(
                  title: 'Halo, ${widget.profile.fullName}',
                  subtitle: 'Pilih teknisi dan buat pesanan servis',
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: _CustomerHero(activeOrders: activeOrders),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: MobileSectionHeader(
                    title: 'Kategori',
                    subtitle: 'Layanan aktif dari admin',
                    action: TextButton(
                      onPressed: _refresh,
                      child: const Text('Sync'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 106,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    scrollDirection: Axis.horizontal,
                    itemCount: data.categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final category = data.categories[index];
                      return Container(
                        width: 102,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              categoryIcon(category.name),
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: MobileSectionHeader(
                    title: 'Teknisi verified',
                    subtitle: 'Pilih sendiri teknisi untuk pesanan',
                  ),
                ),
                const SizedBox(height: 12),
                if (data.technicians.isEmpty)
                  const SizedBox(
                    height: 260,
                    child: EmptyState(message: 'Belum ada teknisi verified'),
                  )
                else
                  for (final technician in data.technicians)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                      child: _TechTile(
                        technician: technician,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TechnicianDetailPage(
                              technicianId: technician.id,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CustomerHero extends StatelessWidget {
  const _CustomerHero({required this.activeOrders});

  final int activeOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Servis datang ke alamatmu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$activeOrders pesanan aktif. Semua status tersimpan di Supabase.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechTile extends StatelessWidget {
  const _TechTile({required this.technician, required this.onTap});

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
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE6F6F6),
                child: Icon(
                  Icons.engineering_rounded,
                  color: AppColors.secondary,
                ),
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
                      technician.skills.isEmpty
                          ? technician.serviceArea
                          : '${technician.skills.take(2).join(', ')} - ${technician.serviceArea}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
