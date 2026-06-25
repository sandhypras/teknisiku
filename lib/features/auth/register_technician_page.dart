import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';

class RegisterTechnicianPage extends StatefulWidget {
  const RegisterTechnicianPage({super.key});

  @override
  State<RegisterTechnicianPage> createState() => _RegisterTechnicianPageState();
}

class _RegisterTechnicianPageState extends State<RegisterTechnicianPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _skills = TextEditingController();
  final _experience = TextEditingController();
  final _description = TextEditingController();
  late final AuthService _auth;
  late final MarketplaceRepository _repo;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _auth = AuthService(client);
    _repo = MarketplaceRepository(client);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _address.dispose();
    _skills.dispose();
    _experience.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.registerTechnician(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
      );
      await _repo.upsertTechnicianProfile(
        address: _address.text.trim(),
        experience: _experience.text.trim(),
        skills: _skills.text.trim(),
        serviceArea: 'Solo',
        description: _description.text.trim(),
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Teknisi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Ajukan verifikasi teknisi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Status awal pending. Setelah admin menyetujui, layanan kamu dapat tampil ke customer.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_name, 'Nama lengkap', Icons.person_outline),
                  _field(
                    _email,
                    'Email',
                    Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    _password,
                    'Password',
                    Icons.lock_outline,
                    obscure: true,
                  ),
                  _field(
                    _phone,
                    'Nomor telepon',
                    Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  _field(
                    _address,
                    'Alamat',
                    Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  _field(
                    _skills,
                    'Keahlian, pisahkan koma',
                    Icons.build_outlined,
                  ),
                  _field(
                    _experience,
                    'Pengalaman',
                    Icons.work_outline,
                    maxLines: 2,
                  ),
                  _field(
                    _description,
                    'Deskripsi profil',
                    Icons.notes_outlined,
                    maxLines: 3,
                  ),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Memproses...' : 'Daftar Teknisi'),
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

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLines: obscure ? 1 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return '$label wajib diisi';
          if (label == 'Email' && !text.contains('@')) {
            return 'Format email belum sesuai';
          }
          if (label == 'Password' && text.length < 6) {
            return 'Password minimal 6 karakter';
          }
          return null;
        },
      ),
    );
  }
}
