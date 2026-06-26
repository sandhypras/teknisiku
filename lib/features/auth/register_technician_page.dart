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
  bool _obscurePassword = true;
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
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            const _TechRegisterBackdrop(),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE7EEF7)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.engineering_rounded,
                            color: Color(0xFF0876ED),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Teknisi',
                            style: TextStyle(
                              color: Color(0xFF07143D),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/logos/logoku.png',
                  width: 126,
                  height: 126,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Daftar Teknisi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF07143D),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lengkapi profil agar admin dapat memverifikasi akun teknisi kamu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF59657C),
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 26),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _TechRegisterField(
                        controller: _name,
                        hint: 'Nama lengkap',
                        icon: Icons.person_outline_rounded,
                        validator: _required('Nama lengkap'),
                      ),
                      _TechRegisterField(
                        controller: _email,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
                      ),
                      _TechRegisterField(
                        controller: _password,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF7B8498),
                          ),
                        ),
                        validator: _passwordValidator,
                      ),
                      _TechRegisterField(
                        controller: _phone,
                        hint: 'Nomor telepon',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _required('Nomor telepon'),
                      ),
                      _TechRegisterField(
                        controller: _address,
                        hint: 'Alamat',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: _required('Alamat'),
                      ),
                      _TechRegisterField(
                        controller: _skills,
                        hint: 'Keahlian, pisahkan koma',
                        icon: Icons.build_outlined,
                        validator: _required('Keahlian'),
                      ),
                      _TechRegisterField(
                        controller: _experience,
                        hint: 'Pengalaman kerja',
                        icon: Icons.work_outline_rounded,
                        maxLines: 2,
                        validator: _required('Pengalaman'),
                      ),
                      _TechRegisterField(
                        controller: _description,
                        hint: 'Deskripsi profil',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                        validator: _required('Deskripsi profil'),
                      ),
                      if (_error != null) ...[
                        _TechRegisterError(message: _error!),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0876ED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: Text(
                            _loading ? 'Memproses...' : 'Daftar Teknisi',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => Navigator.maybePop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0876ED),
                            side: const BorderSide(
                              color: Color(0xFF0876ED),
                              width: 1.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text(
                            'Sudah punya akun? Masuk',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _TechRegisterField extends StatelessWidget {
  const _TechRegisterField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: _techRegisterCardDecoration(radius: 16),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          validator: validator,
          style: const TextStyle(
            color: Color(0xFF07143D),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF7B8498),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF0876ED), size: 26),
            suffixIcon: suffix,
            border: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _TechRegisterBackdrop extends StatelessWidget {
  const _TechRegisterBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -12,
            top: 156,
            child: Icon(
              Icons.business_center_outlined,
              size: 118,
              color: const Color(0xFF0876ED).withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            right: -2,
            top: 118,
            child: Icon(
              Icons.handyman_outlined,
              size: 112,
              color: const Color(0xFF0876ED).withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: 34,
            bottom: 90,
            child: Icon(
              Icons.router_outlined,
              size: 92,
              color: const Color(0xFF0876ED).withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechRegisterError extends StatelessWidget {
  const _TechRegisterError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),
    );
  }
}

String? Function(String?) _required(String label) {
  return (value) {
    if ((value ?? '').trim().isEmpty) return '$label wajib diisi';
    return null;
  };
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  if (!email.contains('@')) return 'Format email belum sesuai';
  return null;
}

String? _passwordValidator(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password wajib diisi';
  if (password.length < 6) return 'Password minimal 6 karakter';
  return null;
}

BoxDecoration _techRegisterCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE7EEF7)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
