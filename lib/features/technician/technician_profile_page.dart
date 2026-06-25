import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'technician_shell_page.dart';

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
  late Future<TechnicianSummary?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.myTechnicianProfile();
  }

  void _refresh() =>
      setState(() => _future = widget.repo.myTechnicianProfile());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<TechnicianSummary?>(
        future: _future,
        builder: (context, snapshot) {
          final technician = snapshot.data;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const TechnicianHeader(
                title: 'Profil Teknisi',
                subtitle: 'Data profil dan status verifikasi',
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Container(
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
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.secondary.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              widget.profile.fullName.isEmpty
                                  ? 'T'
                                  : widget.profile.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profile.fullName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(widget.profile.email),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      StatusPill(
                        label: technician?.status ?? 'belum lengkap',
                        color: technician?.status == 'verified'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        technician?.description ??
                            'Lengkapi profil agar admin dapat memverifikasi akun teknisi.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showProfileSheet(technician),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Lengkapi / Edit Profil'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.authService.signOut,
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Keluar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
      builder: (context) => Padding(
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
              'Profil teknisi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: skills,
              decoration: const InputDecoration(
                labelText: 'Keahlian, pisahkan koma',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: experience,
              decoration: const InputDecoration(labelText: 'Pengalaman'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: area,
              decoration: const InputDecoration(labelText: 'Area layanan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
              maxLines: 3,
            ),
            const SizedBox(height: 18),
            FilledButton(
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
              child: const Text('Simpan Profil'),
            ),
          ],
        ),
      ),
    );
  }
}
