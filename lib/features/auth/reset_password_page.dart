import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({required this.onComplete, super.key});

  final Future<void> Function() onComplete;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final AuthService _authService;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.updatePassword(password: _password.text);
      await widget.onComplete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru berhasil disimpan.')),
      );
    } catch (error) {
      setState(
        () => _error =
            'Password belum bisa disimpan. Buka ulang link reset atau coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Image.asset('assets/logos/logoku.png', width: 136, height: 136),
            const SizedBox(height: 20),
            const Text(
              'Buat Password Baru',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF07143D),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Masukkan password baru untuk akun Si Teknisi kamu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF59657C),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _ResetPasswordField(
                    controller: _password,
                    hint: 'Password baru',
                    obscureText: _obscurePassword,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF7B8498),
                      ),
                    ),
                    validator: _passwordValidator,
                  ),
                  const SizedBox(height: 16),
                  _ResetPasswordField(
                    controller: _confirmPassword,
                    hint: 'Ulangi password baru',
                    obscureText: _obscureConfirmPassword,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: const Color(0xFF7B8498),
                      ),
                    ),
                    validator: (value) {
                      final message = _passwordValidator(value);
                      if (message != null) {
                        return message;
                      }
                      if (value != _password.text) {
                        return 'Konfirmasi password belum sama';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ResetPasswordError(message: _error!),
            ],
            const SizedBox(height: 22),
            SizedBox(
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
                  _loading ? 'Menyimpan...' : 'Simpan Password',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetPasswordField extends StatelessWidget {
  const _ResetPasswordField({
    required this.controller,
    required this.hint,
    required this.obscureText,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _resetCardDecoration(radius: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
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
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF0876ED),
            size: 26,
          ),
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
    );
  }
}

class _ResetPasswordError extends StatelessWidget {
  const _ResetPasswordError({required this.message});

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

String? _passwordValidator(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password wajib diisi';
  if (password.length < 6) return 'Password minimal 6 karakter';
  return null;
}

BoxDecoration _resetCardDecoration({required double radius}) {
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
