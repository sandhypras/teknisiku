import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';

class VerifyEmailOtpPage extends StatefulWidget {
  const VerifyEmailOtpPage({
    required this.email,
    required this.roleLabel,
    required this.onVerified,
    super.key,
  });

  final String email;
  final String roleLabel;
  final Future<void> Function() onVerified;

  @override
  State<VerifyEmailOtpPage> createState() => _VerifyEmailOtpPageState();
}

class _VerifyEmailOtpPageState extends State<VerifyEmailOtpPage> {
  final _otpController = TextEditingController();
  late final AuthService _authService;
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _otpController.text.trim();
    if (token.length != 8) {
      setState(() => _error = 'Masukkan kode OTP 8 digit dari email.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await _authService.verifySignupOtp(email: widget.email, token: token);
      await widget.onVerified();
      if (!mounted) return;
      setState(
        () => _success = 'Email berhasil diverifikasi. Akun siap digunakan.',
      );
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      setState(() => _error = _otpErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _success = null;
    });
    try {
      await _authService.resendSignupOtp(email: widget.email);
      if (mounted) {
        setState(() => _success = 'Kode OTP baru sudah dikirim ke email.');
      }
    } catch (error) {
      setState(
        () =>
            _error = 'Kode belum bisa dikirim ulang. Coba beberapa saat lagi.',
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  String _otpErrorMessage(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('expired')) {
        return 'Kode OTP sudah kedaluwarsa. Kirim ulang kode lalu coba lagi.';
      }
      if (message.contains('invalid') || message.contains('token')) {
        return 'Kode OTP belum sesuai. Periksa email lalu coba lagi.';
      }
    }
    return 'Verifikasi belum berhasil. Pastikan kode OTP sudah benar.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _loading ? null : () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const SizedBox(height: 28),
            Image.asset('assets/logos/logoku.png', width: 124, height: 124),
            const SizedBox(height: 18),
            const Text(
              'Verifikasi Email',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF07143D),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kode OTP akun ${widget.roleLabel} sudah dikirim ke ${widget.email}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF59657C),
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: _otpCardDecoration(radius: 16),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) => _verify(),
                style: const TextStyle(
                  color: Color(0xFF07143D),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '00000000',
                  hintStyle: TextStyle(
                    color: Color(0xFFB3BCCB),
                    letterSpacing: 8,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 22),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null) _OtpBanner(message: _error!, isError: true),
            if (_success != null)
              _OtpBanner(message: _success!, isError: false),
            const SizedBox(height: 16),
            SizedBox(
              height: 58,
              child: FilledButton(
                onPressed: _loading ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0876ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  _loading ? 'Memverifikasi...' : 'Verifikasi Kode',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loading || _resending ? null : _resend,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                _resending ? 'Mengirim ulang...' : 'Kirim ulang kode',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBanner extends StatelessWidget {
  const _OtpBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : const Color(0xFF14804A);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

BoxDecoration _otpCardDecoration({required double radius}) {
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
