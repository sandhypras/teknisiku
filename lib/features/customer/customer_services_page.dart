import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'technician_detail_page.dart';

class CustomerServicesPage extends StatefulWidget {
  const CustomerServicesPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<CustomerServicesPage> createState() => _CustomerServicesPageState();
}

class _CustomerServicesPageState extends State<CustomerServicesPage> {
  late Future<_CustomerServicesData> _future;
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

  Future<_CustomerServicesData> _load() async {
    final results = await Future.wait([
      widget.repo.categories(),
      widget.repo.technicians(),
    ]);
    return _CustomerServicesData(
      categories: results[0] as List<ServiceCategory>,
      technicians: results[1] as List<TechnicianSummary>,
    );
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<_CustomerServicesData>(
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const _ServicesHeader(),
                const SizedBox(height: 16),
                _SearchField(controller: _searchController),
                const SizedBox(height: 22),
                const MobileSectionHeader(
                  title: 'Kategori Populer',
                  subtitle: 'Layanan aktif yang tersedia',
                ),
                const SizedBox(height: 12),
                _CategoryList(categories: data.categories),
                const SizedBox(height: 24),
                MobileSectionHeader(
                  title: 'Teknisi Tersedia',
                  subtitle: '${technicians.length} teknisi siap membantu',
                ),
                const SizedBox(height: 12),
                if (technicians.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: EmptyState(
                      message: 'Belum ada teknisi yang cocok',
                      icon: Icons.engineering_outlined,
                    ),
                  )
                else
                  for (final technician in technicians) ...[
                    _TechnicianTile(
                      technician: technician,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TechnicianDetailPage(technicianId: technician.id),
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
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset('assets/logos/logoku.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layanan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pilih kategori dan teknisi yang sesuai',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: _serviceDecoration(18),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'Cari teknisi atau keahlian...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.secondary),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.categories});

  final List<ServiceCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 160,
        child: EmptyState(message: 'Belum ada kategori aktif'),
      );
    }

    return SizedBox(
      height: 114,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 128,
            padding: const EdgeInsets.all(12),
            decoration: _serviceDecoration(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceIcon(category: category),
                const Spacer(),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
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

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final iconUrl = category.iconUrl;
    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: iconUrl == null || iconUrl.isEmpty
          ? Icon(categoryIcon(category.name), color: AppColors.secondary)
          : Image.network(
              iconUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(categoryIcon(category.name), color: AppColors.secondary),
            ),
    );
  }
}

class _TechnicianTile extends StatelessWidget {
  const _TechnicianTile({required this.technician, required this.onTap});

  final TechnicianSummary technician;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = technician.rating == 0
        ? 'Baru'
        : technician.rating.toStringAsFixed(1);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _serviceDecoration(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.engineering_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      technician.skills.isEmpty
                          ? 'Spesialis Teknisi'
                          : technician.skills.take(3).join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
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
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            technician.serviceArea,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _serviceDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE7EEF7)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.07),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _CustomerServicesData {
  const _CustomerServicesData({
    required this.categories,
    required this.technicians,
  });

  final List<ServiceCategory> categories;
  final List<TechnicianSummary> technicians;
}
