import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/app.dart';
import '../../app/theme.dart';
import '../../core/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _LoginRole { customer, technician }

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;
  _LoginRole _selectedRole = _LoginRole.customer;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRegister() {
    Navigator.pushNamed(
      context,
      _selectedRole == _LoginRole.customer
          ? AppRoutes.registerCustomer
          : AppRoutes.registerTechnician,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            const _AuthBackdrop(),
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF07143D),
                  ),
                ),
                const SizedBox(height: 34),
                const _BrandHero(),
                const SizedBox(height: 54),
                const Text(
                  'Selamat Datang!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF07143D),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      color: Color(0xFF59657C),
                      fontSize: 17,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: 'Masuk untuk melanjutkan dan nikmati\n'),
                      TextSpan(text: 'layanan terbaik dari '),
                      TextSpan(
                        text: 'Si Teknisi.',
                        style: TextStyle(color: Color(0xFF006FE6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _AuthTextField(
                        controller: _emailController,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Email wajib diisi';
                          if (!email.contains('@')) {
                            return 'Format email belum sesuai';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _AuthTextField(
                        controller: _passwordController,
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
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (value!.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: Color(0xFF006FE6),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: 14),
                ] else
                  const SizedBox(height: 14),
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
                      _loading ? 'Memproses...' : 'Masuk',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 58,
                  child: OutlinedButton(
                    onPressed: _openRegister,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0876ED),
                      side: const BorderSide(
                        color: Color(0xFF0876ED),
                        width: 1.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const _DividerLabel(label: 'Masuk sebagai'),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        selected: _selectedRole == _LoginRole.customer,
                        icon: Icons.person_rounded,
                        title: 'Customer',
                        subtitle: 'Saya ingin meminta\nlayanan',
                        onTap: () =>
                            setState(() => _selectedRole = _LoginRole.customer),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _RoleCard(
                        selected: _selectedRole == _LoginRole.technician,
                        imageAsset: 'assets/logos/logoku.png',
                        title: 'Teknisi',
                        subtitle: 'Saya ingin menerima\npekerjaan',
                        onTap: () => setState(
                          () => _selectedRole = _LoginRole.technician,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const _AdminNotice(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/logos/logoku.png',
          width: 190,
          height: 190,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 2),
        const Text(
          'Si Teknisi',
          style: TextStyle(
            color: Color(0xFF0964CC),
            fontSize: 45,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 0.92,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Solusi Cepat, Hasil Tepat',
          style: TextStyle(
            color: Color(0xFF0964CC),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 22,
            top: 178,
            child: _OutlineToolIcon(
              icon: Icons.settings_outlined,
              size: 82,
              opacity: 0.10,
            ),
          ),
          Positioned(
            right: 8,
            top: 185,
            child: _OutlineToolIcon(
              icon: Icons.handyman_outlined,
              size: 118,
              opacity: 0.09,
            ),
          ),
          Positioned(
            left: -22,
            top: 292,
            child: _OutlineToolIcon(
              icon: Icons.business_center_outlined,
              size: 130,
              opacity: 0.08,
            ),
          ),
          Positioned(
            right: 30,
            top: 342,
            child: _OutlineToolIcon(
              icon: Icons.router_outlined,
              size: 118,
              opacity: 0.09,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineToolIcon extends StatelessWidget {
  const _OutlineToolIcon({
    required this.icon,
    required this.size,
    required this.opacity,
  });

  final IconData icon;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: const Color(0xFF0876ED).withValues(alpha: opacity),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _authCardDecoration(radius: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(
          color: Color(0xFF07143D),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF7B8498),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF0876ED), size: 28),
          suffixIcon: suffix,
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDCE5F1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF07143D),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDCE5F1))),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.imageAsset,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0876ED)
                  : const Color(0xFFE7EEF7),
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF234D79).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: [
              if (selected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFF0876ED),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF4FF),
                        shape: BoxShape.circle,
                      ),
                      child: imageAsset == null
                          ? Icon(icon, color: const Color(0xFF0876ED), size: 42)
                          : Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(imageAsset!),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF0876ED)
                            : const Color(0xFF07143D),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF59657C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: Color(0xFFEAF4FF),
          child: Icon(Icons.info_rounded, color: Color(0xFF0876ED), size: 20),
        ),
        SizedBox(width: 12),
        Flexible(
          child: Text(
            'Akun Admin dikelola melalui website.',
            style: TextStyle(
              color: Color(0xFF59657C),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _authCardDecoration({required double radius}) {
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
