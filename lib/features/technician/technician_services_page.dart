import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'technician_shell_page.dart';

class TechnicianServicesPage extends StatefulWidget {
  const TechnicianServicesPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<TechnicianServicesPage> createState() => _TechnicianServicesPageState();
}

class _TechnicianServicesPageState extends State<TechnicianServicesPage> {
  late Future<_TechnicianServicesData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TechnicianServicesData> _load() async {
    final technician = await widget.repo.myTechnicianProfile();
    final categories = await widget.repo.categories();
    final services = technician == null
        ? <TechnicianService>[]
        : await widget.repo.services(
            technicianId: technician.id,
            publicOnly: false,
          );
    return _TechnicianServicesData(
      technician: technician,
      categories: categories,
      services: services,
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_TechnicianServicesData>(
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
          return Column(
            children: [
              TechnicianHeader(
                title: 'Layanan Saya',
                subtitle: 'Layanan baru masuk status pending admin',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: data.technician == null
                        ? null
                        : () => _showAddServiceSheet(data),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Layanan'),
                  ),
                ),
              ),
              Expanded(
                child: data.technician == null
                    ? const EmptyState(message: 'Lengkapi profil teknisi dulu')
                    : data.services.isEmpty
                    ? const EmptyState(message: 'Belum ada layanan')
                    : RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(18),
                          itemCount: data.services.length,
                          itemBuilder: (_, index) =>
                              _ServiceCard(service: data.services[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddServiceSheet(_TechnicianServicesData data) {
    final name = TextEditingController();
    final description = TextEditingController();
    final price = TextEditingController();
    final duration = TextEditingController(text: '1-2 jam');
    ServiceCategory? category = data.categories.isEmpty
        ? null
        : data.categories.first;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.viewInsetsOf(context).bottom + 18,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Tambah layanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<ServiceCategory>(
                initialValue: category,
                items: data.categories
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item.name)),
                    )
                    .toList(),
                onChanged: (value) => setSheet(() => category = value),
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama layanan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Estimasi harga'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: duration,
                decoration: const InputDecoration(labelText: 'Estimasi durasi'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  if (category == null || name.text.trim().isEmpty) {
                    return;
                  }
                  await widget.repo.createTechnicianService(
                    technicianId: data.technician!.id,
                    categoryId: category!.id,
                    name: name.text.trim(),
                    description: description.text.trim(),
                    price: double.tryParse(price.text.trim()) ?? 0,
                    duration: duration.text.trim(),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (mounted) _refresh();
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final TechnicianService service;

  @override
  Widget build(BuildContext context) {
    final color = switch (service.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            categoryIcon(service.categoryName ?? ''),
            color: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${formatRupiah(service.price)} - ${service.categoryName ?? '-'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          StatusPill(label: service.status, color: color),
        ],
      ),
    );
  }
}

class _TechnicianServicesData {
  const _TechnicianServicesData({
    required this.technician,
    required this.categories,
    required this.services,
  });

  final TechnicianSummary? technician;
  final List<ServiceCategory> categories;
  final List<TechnicianService> services;
}
