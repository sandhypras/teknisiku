import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';

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

  void _refresh() => setState(() {
    _future = _load();
  });

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
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                _ServicesHeader(
                  onAdd: data.technician == null
                      ? null
                      : () async {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => AddTechnicianServicePage(
                                repo: widget.repo,
                                technician: data.technician!,
                                categories: data.categories,
                              ),
                            ),
                          );
                          if (saved == true && mounted) _refresh();
                        },
                ),
                const SizedBox(height: 18),
                _InfoBanner(
                  text:
                      'Layanan baru yang Anda tambahkan memerlukan persetujuan admin sebelum dapat ditampilkan ke pelanggan.',
                ),
                const SizedBox(height: 20),
                if (data.technician == null)
                  const SizedBox(
                    height: 320,
                    child: EmptyState(message: 'Lengkapi profil teknisi dulu'),
                  )
                else if (data.services.isEmpty)
                  const SizedBox(
                    height: 320,
                    child: EmptyState(message: 'Belum ada layanan'),
                  )
                else
                  for (final service in data.services) ...[
                    _ServiceCard(service: service),
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

class AddTechnicianServicePage extends StatefulWidget {
  const AddTechnicianServicePage({
    required this.repo,
    required this.technician,
    required this.categories,
    super.key,
  });

  final MarketplaceRepository repo;
  final TechnicianSummary technician;
  final List<ServiceCategory> categories;

  @override
  State<AddTechnicianServicePage> createState() =>
      _AddTechnicianServicePageState();
}

class _AddTechnicianServicePageState extends State<AddTechnicianServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  ServiceCategory? _category;
  bool _available = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _category = widget.categories.isEmpty ? null : widget.categories.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _error = 'Kategori layanan belum tersedia.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repo.createTechnicianService(
        technicianId: widget.technician.id,
        categoryId: _category!.id,
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.tryParse(_price.text.trim().replaceAll('.', '')) ?? 0,
        duration: _duration.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                children: [
                  _SquareAction(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Tambah Layanan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const _SquareAction(icon: Icons.description_outlined),
                ],
              ),
              const SizedBox(height: 24),
              _InfoBanner(
                text:
                    'Layanan baru yang Anda tambahkan memerlukan persetujuan dari admin sebelum dapat ditampilkan ke pelanggan.',
              ),
              const SizedBox(height: 18),
              _FieldLabel('Kategori *'),
              _CategoryPicker(
                category: _category,
                categories: widget.categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              _FieldLabel('Nama Layanan *'),
              _ServiceInput(
                controller: _name,
                hint: 'Masukkan nama layanan',
                icon: Icons.local_offer_outlined,
                validator: _required('Nama layanan'),
              ),
              _FieldLabel('Deskripsi *'),
              _ServiceInput(
                controller: _description,
                hint: 'Jelaskan layanan yang Anda tawarkan',
                icon: Icons.notes_rounded,
                maxLines: 4,
                validator: _required('Deskripsi'),
              ),
              _FieldLabel('Harga Perkiraan *'),
              _ServiceInput(
                controller: _price,
                hint: 'Contoh: 150000',
                icon: Icons.payments_rounded,
                suffixText: 'Rp',
                keyboardType: TextInputType.number,
                validator: _priceValidator,
              ),
              _FieldLabel('Estimasi Waktu *'),
              _ServiceInput(
                controller: _duration,
                hint: 'Contoh: 1-2 jam / 60 menit',
                icon: Icons.schedule_rounded,
                validator: _required('Estimasi waktu'),
              ),
              _FieldLabel('Upload Foto (Opsional)'),
              const _UploadBox(),
              _FieldLabel('Status Tersedia *'),
              _AvailabilitySelector(
                available: _available,
                onChanged: (value) => setState(() => _available = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(message: _error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: _loading || !_available ? null : _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _loading ? 'Menyimpan...' : 'Simpan Layanan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
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

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoMark(size: 58),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Layanan Saya',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Kelola layanan yang terhubung ke database.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _SquareAction(icon: Icons.add_rounded, onTap: onAdd),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.info_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(16),
      decoration: _serviceDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              categoryIcon(service.categoryName ?? service.name),
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatRupiah(service.price)} - ${service.duration ?? 'Estimasi belum diisi'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.category,
    required this.categories,
    required this.onChanged,
  });

  final ServiceCategory? category;
  final List<ServiceCategory> categories;
  final ValueChanged<ServiceCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _serviceDecoration(radius: 12),
      child: DropdownButtonFormField<ServiceCategory>(
        initialValue: category,
        items: categories
            .map(
              (item) => DropdownMenuItem(value: item, child: Text(item.name)),
            )
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Kategori wajib dipilih' : null,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        decoration: const InputDecoration(
          hintText: 'Pilih kategori layanan',
          prefixIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}

class _ServiceInput extends StatelessWidget {
  const _ServiceInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.suffixText,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _serviceDecoration(radius: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixText: suffixText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.28),
          style: BorderStyle.solid,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 38),
          SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload foto layanan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Format: JPG, PNG (maks. 5MB)\nMaksimal 5 foto',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySelector extends StatelessWidget {
  const _AvailabilitySelector({
    required this.available,
    required this.onChanged,
  });

  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _serviceDecoration(radius: 12),
      child: Row(
        children: [
          Expanded(
            child: _AvailabilityOption(
              selected: available,
              title: 'Tersedia',
              caption: 'Layanan siap dipesan',
              onTap: () => onChanged(true),
            ),
          ),
          Container(width: 1, height: 72, color: const Color(0xFFE4ECF6)),
          Expanded(
            child: _AvailabilityOption(
              selected: !available,
              title: 'Tidak Tersedia',
              caption: 'Sementara tidak menerima pesanan',
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityOption extends StatelessWidget {
  const _AvailabilityOption({
    required this.selected,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : const Color(0xFFB8C5D8),
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    caption,
                    maxLines: 2,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
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

class _SquareAction extends StatelessWidget {
  const _SquareAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 52,
        height: 52,
        decoration: _serviceDecoration(radius: 14),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger, fontSize: 12),
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

String? Function(String?) _required(String label) {
  return (value) {
    if ((value ?? '').trim().isEmpty) return '$label wajib diisi';
    return null;
  };
}

String? _priceValidator(String? value) {
  final raw = (value ?? '').trim().replaceAll('.', '');
  if (raw.isEmpty) return 'Harga wajib diisi';
  if ((double.tryParse(raw) ?? 0) <= 0) return 'Harga harus lebih dari 0';
  return null;
}

BoxDecoration _serviceDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE4ECF6)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.07),
        blurRadius: 14,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
