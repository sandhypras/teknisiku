import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../../shared/widgets/app_feedback.dart';

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
                  onAdd: () async {
                    final technician = data.technician;
                    if (technician == null) {
                      AppFeedback.warning(
                        context,
                        title: 'Profil belum lengkap',
                        message:
                            'Lengkapi profil teknisi terlebih dahulu sebelum menambahkan layanan.',
                      );
                      return;
                    }
                    if (technician.status != 'verified') {
                      AppFeedback.warning(
                        context,
                        title: 'Verifikasi belum selesai',
                        message:
                            'Akun teknisi harus diverifikasi admin sebelum dapat menambahkan layanan.',
                      );
                      return;
                    }
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => AddTechnicianServicePage(
                          repo: widget.repo,
                          technician: technician,
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
                    _ServiceCard(
                      service: service,
                      onTap: () async {
                        final saved = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => AddTechnicianServicePage(
                              repo: widget.repo,
                              technician: data.technician!,
                              categories: data.categories,
                              service: service,
                            ),
                          ),
                        );
                        if (saved == true && mounted) _refresh();
                      },
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

class AddTechnicianServicePage extends StatefulWidget {
  const AddTechnicianServicePage({
    required this.repo,
    required this.technician,
    required this.categories,
    this.service,
    super.key,
  });

  final MarketplaceRepository repo;
  final TechnicianSummary technician;
  final List<ServiceCategory> categories;
  final TechnicianService? service;

  @override
  State<AddTechnicianServicePage> createState() =>
      _AddTechnicianServicePageState();
}

class _AddTechnicianServicePageState extends State<AddTechnicianServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _duration = TextEditingController();
  ServiceCategory? _category;
  bool _loading = false;
  String? _error;
  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageContentType;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _name.text = service?.name ?? '';
    _description.text = service?.description ?? '';
    _price.text = service == null ? '' : service.price.toStringAsFixed(0);
    _duration.text = service?.duration ?? '';
    _imageUrl = service?.imageUrl;
    _category = service == null
        ? (widget.categories.isEmpty ? null : widget.categories.first)
        : widget.categories
              .where((item) => item.id == service.categoryId)
              .firstOrNull;
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
      _showInlineError('Kategori layanan belum tersedia.');
      return;
    }
    if (widget.technician.status != 'verified') {
      _showInlineError(
        'Akun teknisi harus diverifikasi admin sebelum layanan dapat disimpan.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var imageUrl = _imageUrl;
      if (_imageBytes != null) {
        imageUrl = await widget.repo.uploadServiceImage(
          technicianId: widget.technician.id,
          bytes: _imageBytes!,
          fileName: _imageFileName ?? 'service.jpg',
          contentType: _imageContentType,
        );
      }
      final service = widget.service;
      if (service == null) {
        await widget.repo.createTechnicianService(
          technicianId: widget.technician.id,
          categoryId: _category!.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: double.tryParse(_price.text.trim().replaceAll('.', '')) ?? 0,
          duration: _duration.text.trim(),
          imageUrl: imageUrl,
        );
      } else {
        await widget.repo.updateTechnicianService(
          serviceId: service.id,
          categoryId: _category!.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          price: double.tryParse(_price.text.trim().replaceAll('.', '')) ?? 0,
          duration: _duration.text.trim(),
          imageUrl: imageUrl,
        );
      }
      if (!mounted) return;
      AppFeedback.success(
        context,
        title: widget.service == null
            ? 'Layanan ditambahkan'
            : 'Layanan diedit',
        message:
            'Layanan tersimpan dan menunggu persetujuan admin sebelum tampil ke customer.',
      );
      Navigator.pop(context, true);
    } catch (error) {
      _showInlineError(_friendlyServiceError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 86,
      maxWidth: 1400,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageFileName = file.name;
      _imageContentType = file.mimeType;
    });
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImageSourceTile(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari galeri',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
              _ImageSourceTile(
                icon: Icons.photo_camera_rounded,
                title: 'Ambil dari kamera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInlineError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    AppFeedback.error(
      context,
      title: 'Layanan gagal disimpan',
      message: message,
    );
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
                  Expanded(
                    child: Text(
                      widget.service == null
                          ? 'Tambah Layanan'
                          : 'Edit Layanan',
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
                hint: 'Contoh: Rp150.000',
                icon: Icons.payments_rounded,
                prefixText: 'Rp ',
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
              _UploadBox(
                imageUrl: _imageUrl,
                imageBytes: _imageBytes,
                onTap: _showImageOptions,
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(message: _error!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 58,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
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
  const _ServiceCard({required this.service, required this.onTap});

  final TechnicianService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (service.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.danger,
      _ => AppColors.warning,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _serviceDecoration(radius: 18),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 68,
                height: 68,
                color: const Color(0xFFEAF4FF),
                child: service.imageUrl?.isNotEmpty == true
                    ? Image.network(
                        service.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          categoryIcon(service.categoryName ?? service.name),
                          color: AppColors.primary,
                          size: 38,
                        ),
                      )
                    : Icon(
                        categoryIcon(service.categoryName ?? service.name),
                        color: AppColors.primary,
                        size: 38,
                      ),
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
            const SizedBox(width: 6),
            const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
          ],
        ),
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
    this.prefixText,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? prefixText;

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
          prefixText: prefixText,
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
  const _UploadBox({required this.onTap, this.imageUrl, this.imageBytes});

  final VoidCallback onTap;
  final String? imageUrl;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                children: [
                  Positioned.fill(
                    child: imageBytes != null
                        ? Image.memory(imageBytes!, fit: BoxFit.cover)
                        : Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Ganti foto',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_rounded,
                    color: AppColors.primary,
                    size: 38,
                  ),
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
                        'Format: JPG, PNG, WEBP',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
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

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFFF4F9FF),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      trailing: const Icon(Icons.chevron_right_rounded),
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

String _friendlyServiceError(Object error) {
  final raw = '$error';
  final lower = raw.toLowerCase();
  if (lower.contains('row-level security') ||
      lower.contains('permission') ||
      lower.contains('42501')) {
    return 'Akun teknisi belum memiliki izin menyimpan layanan. Pastikan akun sudah diverifikasi admin.';
  }
  if (lower.contains('storage') || lower.contains('bucket')) {
    return 'Foto layanan gagal diupload. Coba gunakan file JPG/PNG/WEBP dengan ukuran lebih kecil.';
  }
  if (lower.contains('network') || lower.contains('socketexception')) {
    return 'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
  }
  if (raw.length > 180) {
    return 'Layanan belum dapat disimpan. Coba lagi beberapa saat.';
  }
  return raw;
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
