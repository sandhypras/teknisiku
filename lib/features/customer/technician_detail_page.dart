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
                onRetry: () => setState(() => _future = _load()),
              );
            }
            final data = snapshot.data!;
            final selected = data.services
                .where((item) => _selectedServiceIds.contains(item.id))
                .toList();
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          StatusPill(
                            label: 'Verified',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ProfileHeader(technician: data.technician),
                      const SizedBox(height: 22),
                      MobileSectionHeader(
                        title: 'Layanan',
                        subtitle: 'Pilih satu atau beberapa layanan',
                      ),
                      const SizedBox(height: 12),
                      if (data.services.isEmpty)
                        const SizedBox(
                          height: 240,
                          child: EmptyState(
                            message: 'Teknisi belum punya layanan approved',
                          ),
                        )
                      else
                        for (final service in data.services) ...[
                          _ServiceChoiceCard(
                            service: service,
                            selected: _selectedServiceIds.contains(service.id),
                            onTap: () => setState(() {
                              if (_selectedServiceIds.contains(service.id)) {
                                _selectedServiceIds.remove(service.id);
                              } else {
                                _selectedServiceIds.add(service.id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected.isEmpty
                                ? 'Pilih layanan dulu'
                                : '${selected.length} layanan - ${formatRupiah(selected.fold<double>(0, (sum, item) => sum + item.price))}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: selected.isEmpty
                              ? null
                              : () {
                                  if (Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser ==
                                      null) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.login,
                                    );
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
                          icon: const Icon(Icons.assignment_add),
                          label: const Text('Pesan'),
                        ),
                      ],
                    ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.technician});

  final TechnicianSummary technician;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xFFE6F6F6),
                child: Icon(
                  Icons.engineering_rounded,
                  color: AppColors.secondary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      technician.serviceArea,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (technician.skills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: technician.skills
                  .map(
                    (skill) =>
                        StatusPill(label: skill, color: AppColors.secondary),
                  )
                  .toList(),
            ),
          ],
          if ((technician.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              technician.description!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceChoiceCard extends StatelessWidget {
  const _ServiceChoiceCard({
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
      color: selected
          ? AppColors.secondary.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.secondary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${service.categoryName ?? '-'}${service.duration == null ? '' : ' - ${service.duration}'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupiah(service.price),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
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
