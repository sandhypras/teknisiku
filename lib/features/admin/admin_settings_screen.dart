import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late Future<Map<String, dynamic>> _future;
  final _commissionCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _warrantyCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  @override
  void dispose() {
    _commissionCtrl.dispose();
    _cityCtrl.dispose();
    _warrantyCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final data = await Supabase.instance.client
        .from('app_settings')
        .select('key, value, description')
        .inFilter('key', [
          'commission_percentage',
          'service_city',
          'warranty_days',
        ]);
    final map = {
      for (final row in List<Map<String, dynamic>>.from(data))
        row['key'] as String: row['value'],
    };
    _commissionCtrl.text = '${map['commission_percentage'] ?? 10}';
    _cityCtrl.text = '${map['service_city'] ?? 'Solo'}';
    _warrantyCtrl.text = '${map['warranty_days'] ?? 7}';
    return map;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final db = Supabase.instance.client.from('app_settings');
      await db.upsert([
        {
          'key': 'commission_percentage',
          'value': double.tryParse(_commissionCtrl.text.trim()) ?? 10,
          'description': 'Default application commission percentage',
        },
        {
          'key': 'service_city',
          'value': _cityCtrl.text.trim().isEmpty
              ? 'Solo'
              : _cityCtrl.text.trim(),
          'description': 'Default service city',
        },
        {
          'key': 'warranty_days',
          'value': int.tryParse(_warrantyCtrl.text.trim()) ?? 7,
          'description': 'Default warranty duration after order completion',
        },
      ]);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pengaturan disimpan')));
        setState(() {
          _future = _fetch();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Pengaturan',
            subtitle: 'Kelola konfigurasi aplikasi dari Supabase',
            onRefresh: () => setState(() {
              _future = _fetch();
            }),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AdminErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _future = _fetch();
                    }),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AdminDataCard(
                      child: Column(
                        children: [
                          _SettingField(
                            controller: _commissionCtrl,
                            label: 'Komisi Platform (%)',
                            icon: Icons.percent_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 14),
                          _SettingField(
                            controller: _cityCtrl,
                            label: 'Kota Layanan',
                            icon: Icons.location_city_rounded,
                          ),
                          const SizedBox(height: 14),
                          _SettingField(
                            controller: _warrantyCtrl,
                            label: 'Garansi Default (hari)',
                            icon: Icons.verified_user_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_rounded, size: 18),
                              label: const Text('Simpan Pengaturan'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  const _SettingField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
        filled: true,
        fillColor: AppColors.bgPage,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
