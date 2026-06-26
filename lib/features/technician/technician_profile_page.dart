import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';

class TechnicianProfilePage extends StatefulWidget {
  const TechnicianProfilePage({
    required this.profile,
    required this.repo,
    required this.authService,
    super.key,
  });

  final AppProfile profile;
  final MarketplaceRepository repo;
  final AuthService authService;

  @override
  State<TechnicianProfilePage> createState() => _TechnicianProfilePageState();
}

class _TechnicianProfilePageState extends State<TechnicianProfilePage> {
  final _picker = ImagePicker();
  late Future<_TechnicianProfileData> _future;
  String? _uploadingType;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TechnicianProfileData> _load() async {
    final technician = await widget.repo.myTechnicianProfile();
    final documents = technician == null
        ? <TechnicianDocument>[]
        : await widget.repo.technicianDocuments(technician.id);
    return _TechnicianProfileData(technician: technician, documents: documents);
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  Future<void> _pickDocument({
    required TechnicianSummary technician,
    required String documentType,
    required ImageSource source,
  }) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _uploadingType = documentType);
    try {
      await widget.repo.uploadTechnicianDocument(
        technicianId: technician.id,
        documentType: documentType,
        bytes: await file.readAsBytes(),
        fileName: file.name,
        contentType: file.mimeType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_documentTitle(documentType)} berhasil diupload'),
        ),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload gagal: $error')));
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  void _showUploadOptions(TechnicianSummary? technician, String documentType) {
    if (technician == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi profil teknisi dulu sebelum upload dokumen.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4ECF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F8FE0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upload ${_documentTitle(documentType)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _UploadOptionTile(
                icon: Icons.photo_camera_rounded,
                label: 'Ambil dari kamera',
                subtitle: 'Foto langsung dengan kamera perangkat',
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument(
                    technician: technician,
                    documentType: documentType,
                    source: ImageSource.camera,
                  );
                },
              ),
              const SizedBox(height: 10),
              _UploadOptionTile(
                icon: Icons.photo_library_rounded,
                label: 'Pilih dari galeri',
                subtitle: 'Gunakan foto yang sudah tersimpan',
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument(
                    technician: technician,
                    documentType: documentType,
                    source: ImageSource.gallery,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F8FF), Color(0xFFFAFCFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.35],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_TechnicianProfileData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            final technician = data.technician;
            final completion = _completionRatio(technician, data.documents);
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  const _VerificationTopBar(),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verifikasi Akun Teknisi',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'Lengkapi profil dan unggah KTP serta selfie untuk mulai menerima pekerjaan.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _VerificationStatusPill(status: technician?.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _TechnicianIdentityCard(
                    profile: widget.profile,
                    technician: technician,
                    onEdit: () => _showProfileSheet(technician),
                  ),
                  const SizedBox(height: 22),
                  _ProgressBanner(ratio: completion),
                  const SizedBox(height: 26),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lengkapi Profil & Dokumen',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Foto KTP dan selfie disimpan aman di Supabase Storage.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ChecklistCard(
                    technician: technician,
                    documents: data.documents,
                    uploadingType: _uploadingType,
                    onEdit: () => _showProfileSheet(technician),
                    onUpload: (type) => _showUploadOptions(technician, type),
                  ),
                  const SizedBox(height: 18),
                  const _InfoNotice(),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF4F8FE0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _showProfileSheet(technician),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'Ajukan Verifikasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.lock_outline_rounded, size: 16),
                    label: const Text('Data Anda aman dan terlindungi'),
                    style: TextButton.styleFrom(
                      disabledForegroundColor: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.authService.signOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: Color(0xFFF3D6D6)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _completionRatio(
    TechnicianSummary? technician,
    List<TechnicianDocument> documents,
  ) {
    final hasProfile = technician != null;
    final hasKtp = documents.any((item) => item.documentType == 'ktp');
    final hasSelfie = documents.any((item) => item.documentType == 'selfie');
    final hasSkills = technician?.skills.isNotEmpty == true;
    final hasExperience = (technician?.experience ?? '').trim().isNotEmpty;
    final hasArea = (technician?.serviceArea ?? '').trim().isNotEmpty;
    final flags = [
      hasSelfie,
      hasKtp,
      hasProfile,
      hasExperience,
      hasSkills,
      hasArea,
    ];
    final done = flags.where((flag) => flag).length;
    return flags.isEmpty ? 0 : done / flags.length;
  }

  void _showProfileSheet(TechnicianSummary? technician) {
    final address = TextEditingController(text: '');
    final experience = TextEditingController(
      text: technician?.experience ?? '',
    );
    final skills = TextEditingController(
      text: technician?.skills.join(', ') ?? '',
    );
    final area = TextEditingController(text: technician?.serviceArea ?? 'Solo');
    final description = TextEditingController(
      text: technician?.description ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4ECF6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F8FE0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.badge_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Profil teknisi',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProfileField(
                controller: address,
                label: 'Alamat',
                icon: Icons.home_rounded,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: skills,
                label: 'Keahlian, pisahkan koma',
                icon: Icons.build_rounded,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: experience,
                label: 'Pengalaman',
                icon: Icons.business_center_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: area,
                label: 'Area layanan',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 14),
              _ProfileField(
                controller: description,
                label: 'Deskripsi',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF4F8FE0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await widget.repo.upsertTechnicianProfile(
                        address: address.text.trim().isEmpty
                            ? '-'
                            : address.text.trim(),
                        experience: experience.text.trim(),
                        skills: skills.text.trim(),
                        serviceArea: area.text.trim(),
                        description: description.text.trim(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (mounted) _refresh();
                    },
                    child: const Text(
                      'Simpan Profil',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFF6FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4ECF6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE4ECF6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}

class _UploadOptionTile extends StatelessWidget {
  const _UploadOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6FAFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE4ECF6)),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationTopBar extends StatelessWidget {
  const _VerificationTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SoftButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        const Spacer(),
        const AppLogoMark(size: 54),
        const SizedBox(width: 9),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Si Teknisi',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              'Solusi Cepat, Hasil Tepat',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const Spacer(),
        const _SoftButton(icon: Icons.notifications_none_rounded),
      ],
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF4F8FE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  percent >= 100
                      ? 'Profil lengkap, siap diajukan!'
                      : 'Kelengkapan profil Anda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  percent >= 100
                      ? 'Semua data dan dokumen sudah terisi.'
                      : 'Lengkapi item di bawah agar verifikasi lebih cepat.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
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

class _TechnicianIdentityCard extends StatelessWidget {
  const _TechnicianIdentityCard({
    required this.profile,
    required this.technician,
    required this.onEdit,
  });

  final AppProfile profile;
  final TechnicianSummary? technician;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _profileDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF4F8FE0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFEAF4FF),
                      child: Text(
                        _initials(profile.fullName),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: 2,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.fullName.isEmpty
                                ? 'Teknisi'
                                : profile.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB31A),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(technician?.rating ?? 0) <= 0 ? '0.0' : technician!.rating.toStringAsFixed(1)} (${technician?.completedJobs ?? 0} ulasan)',
                            style: const TextStyle(
                              color: Color(0xFF8A6200),
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _TinyProfileFact(
                            icon: Icons.groups_outlined,
                            label: 'ID Teknisi',
                            value: _shortId(technician?.id ?? profile.id),
                          ),
                        ),
                        Expanded(
                          child: _TinyProfileFact(
                            icon: Icons.work_outline_rounded,
                            label: 'Area',
                            value: technician?.serviceArea ?? 'Solo',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Verifikasi diperlukan untuk memastikan keaslian data dan meningkatkan kepercayaan pelanggan.',
                    style: TextStyle(
                      color: AppColors.primary,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.technician,
    required this.documents,
    required this.uploadingType,
    required this.onEdit,
    required this.onUpload,
  });

  final TechnicianSummary? technician;
  final List<TechnicianDocument> documents;
  final String? uploadingType;
  final VoidCallback onEdit;
  final ValueChanged<String> onUpload;

  @override
  Widget build(BuildContext context) {
    final hasProfile = technician != null;
    final hasKtp = documents.any((item) => item.documentType == 'ktp');
    final hasSelfie = documents.any((item) => item.documentType == 'selfie');
    final hasSkills = technician?.skills.isNotEmpty == true;
    final hasExperience = (technician?.experience ?? '').trim().isNotEmpty;
    final hasArea = (technician?.serviceArea ?? '').trim().isNotEmpty;
    final items = [
      _ChecklistItemData(
        Icons.photo_camera_front_rounded,
        'Foto Selfie',
        'Ambil foto wajah terbaru untuk verifikasi',
        hasSelfie,
        hasSelfie ? 'Selesai' : 'Upload',
        documentType: 'selfie',
        loading: uploadingType == 'selfie',
      ),
      _ChecklistItemData(
        Icons.badge_rounded,
        'KTP',
        'Unggah foto KTP yang masih berlaku',
        hasKtp,
        hasKtp ? 'Selesai' : 'Upload',
        documentType: 'ktp',
        loading: uploadingType == 'ktp',
      ),
      _ChecklistItemData(
        Icons.person_rounded,
        'Profil Teknisi',
        'Nama, area layanan, dan deskripsi profil',
        hasProfile,
        hasProfile ? 'Selesai' : 'Isi',
      ),
      _ChecklistItemData(
        Icons.workspace_premium_rounded,
        'Sertifikat',
        'Unggah sertifikat keahlian (jika ada)',
        false,
        'Unggah',
      ),
      _ChecklistItemData(
        Icons.business_center_rounded,
        'Pengalaman',
        'Informasi pengalaman kerja Anda',
        hasExperience,
        hasExperience ? 'Selesai' : 'Isi',
      ),
      _ChecklistItemData(
        Icons.build_rounded,
        'Keahlian',
        'Pilih keahlian yang Anda kuasai',
        hasSkills,
        hasSkills ? 'Selesai' : 'Pilih',
      ),
      _ChecklistItemData(
        Icons.location_on_rounded,
        'Area Layanan',
        'Pilih area/lokasi layanan Anda',
        hasArea,
        hasArea ? 'Selesai' : 'Pilih',
      ),
    ];
    return Container(
      decoration: _profileDecoration(radius: 20),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ChecklistRow(
              data: items[index],
              onTap: items[index].documentType == null
                  ? onEdit
                  : () => onUpload(items[index].documentType!),
            ),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                color: Color(0xFFEEF3FA),
                indent: 14,
                endIndent: 14,
              ),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.data, required this.onTap});

  final _ChecklistItemData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.done
                      ? AppColors.success.withValues(alpha: 0.10)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  data.icon,
                  color: data.done ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      data.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 98,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: data.done
                      ? AppColors.success.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: data.done ? Colors.transparent : AppColors.primary,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (data.loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else ...[
                      Text(
                        data.action,
                        style: TextStyle(
                          color: data.done
                              ? AppColors.success
                              : AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      if (data.done) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyProfileFact extends StatelessWidget {
  const _TinyProfileFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerificationStatusPill extends StatelessWidget {
  const _VerificationStatusPill({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final value = status ?? 'pending';
    final color = switch (value) {
      'verified' => AppColors.success,
      'rejected' || 'inactive' => AppColors.danger,
      _ => AppColors.warning,
    };
    final label = switch (value) {
      'verified' => 'Terverifikasi',
      'rejected' => 'Ditolak',
      _ => 'Menunggu',
    };
    final icon = switch (value) {
      'verified' => Icons.verified_rounded,
      'rejected' || 'inactive' => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.info_rounded, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pastikan foto KTP terbaca jelas dan selfie menampilkan wajah Anda. Proses verifikasi biasanya memakan waktu 1x24 jam.',
              style: TextStyle(
                color: AppColors.primary,
                height: 1.35,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 50,
        height: 50,
        decoration: _profileDecoration(radius: 15),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _TechnicianProfileData {
  const _TechnicianProfileData({
    required this.technician,
    required this.documents,
  });

  final TechnicianSummary? technician;
  final List<TechnicianDocument> documents;
}

class _ChecklistItemData {
  const _ChecklistItemData(
    this.icon,
    this.title,
    this.caption,
    this.done,
    this.action, {
    this.documentType,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String caption;
  final bool done;
  final String action;
  final String? documentType;
  final bool loading;
}

String _documentTitle(String type) {
  return switch (type) {
    'ktp' => 'KTP',
    'selfie' => 'Foto Selfie',
    _ => 'Dokumen',
  };
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'T';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

String _shortId(String id) {
  if (id.length <= 8) return id;
  return 'STK-${id.substring(0, 8).toUpperCase()}';
}

BoxDecoration _profileDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE4ECF6)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
