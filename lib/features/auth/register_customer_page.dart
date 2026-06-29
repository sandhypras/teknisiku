import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';

class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({super.key});

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  late final AuthService _authService;
  final _picker = ImagePicker();
  XFile? _profilePhoto;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _authService = AuthService(client);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (file != null) setState(() => _profilePhoto = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profilePhoto == null) {
      setState(() => _error = 'Foto profil wajib diupload');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _authService.registerCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      final userId =
          response.user?.id ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw StateError('User gagal dibuat');
      final imagePath = await _uploadProfilePhoto(userId, _profilePhoto!);
      await _saveProfileImage(userId, imagePath);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _uploadProfilePhoto(String userId, XFile file) async {
    final extension = _extensionFor(file.name, file.mimeType);
    final path =
        '$userId/profile-${DateTime.now().millisecondsSinceEpoch}$extension';
    await Supabase.instance.client.storage
        .from('profile-images')
        .uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(
            contentType: file.mimeType ?? _contentTypeFor(extension),
            upsert: true,
          ),
        );
    return 'profile-images/$path';
  }

  Future<void> _saveProfileImage(String userId, String imagePath) async {
    for (var attempt = 0; attempt < 3; attempt += 1) {
      final updated = await Supabase.instance.client
          .from('profiles')
          .update({'profile_image_url': imagePath})
          .eq('id', userId)
          .select('id')
          .maybeSingle();
      if (updated != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    throw StateError('Profil customer belum siap untuk menyimpan foto');
  }

  @override
  Widget build(BuildContext context) {
    return _RegisterShell(
      title: 'Daftar Customer',
      subtitle: 'Buat akun untuk memesan teknisi dan memantau status layanan.',
      roleIcon: Icons.person_rounded,
      roleLabel: 'Customer',
      error: _error,
      loading: _loading,
      formKey: _formKey,
      submitLabel: 'Daftar Customer',
      onSubmit: _submit,
      children: [
        _ProfilePhotoPicker(file: _profilePhoto, onPick: _pickProfilePhoto),
        _RegisterField(
          controller: _nameController,
          hint: 'Nama lengkap',
          icon: Icons.person_outline_rounded,
          validator: _required('Nama lengkap'),
        ),
        _RegisterField(
          controller: _emailController,
          hint: 'Email',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        _RegisterField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
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
        _RegisterField(
          controller: _phoneController,
          hint: 'Nomor telepon',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _required('Nomor telepon'),
        ),
      ],
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({required this.file, required this.onPick});

  final XFile? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _registerCardDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              file == null
                  ? Icons.person_add_alt_1_rounded
                  : Icons.check_circle_rounded,
              color: const Color(0xFF0876ED),
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto profil wajib',
                  style: TextStyle(
                    color: Color(0xFF07143D),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  file == null ? 'Pilih foto wajah customer' : file!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF59657C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_rounded, size: 18),
            label: Text(file == null ? 'Upload' : 'Ganti'),
          ),
        ],
      ),
    );
  }
}

class _RegisterShell extends StatelessWidget {
  const _RegisterShell({
    required this.title,
    required this.subtitle,
    required this.roleIcon,
    required this.roleLabel,
    required this.children,
    required this.formKey,
    required this.onSubmit,
    required this.loading,
    required this.submitLabel,
    this.error,
  });

  final String title;
  final String subtitle;
  final IconData roleIcon;
  final String roleLabel;
  final List<Widget> children;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final bool loading;
  final String submitLabel;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            const _RegisterBackdrop(),
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
                    _RoleBadge(icon: roleIcon, label: roleLabel),
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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF07143D),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF59657C),
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 26),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      for (final child in children) ...[
                        child,
                        const SizedBox(height: 16),
                      ],
                      if (error != null) ...[
                        _RegisterError(message: error!),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: FilledButton(
                          onPressed: loading ? null : onSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0876ED),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: Text(
                            loading ? 'Memproses...' : submitLabel,
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

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _registerCardDecoration(radius: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: 1,
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
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7EEF7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0876ED), size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF07143D),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterBackdrop extends StatelessWidget {
  const _RegisterBackdrop();

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
              Icons.settings_outlined,
              size: 82,
              color: const Color(0xFF0876ED).withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterError extends StatelessWidget {
  const _RegisterError({required this.message});

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

String _extensionFor(String fileName, String? mimeType) {
  final lowerName = fileName.toLowerCase();
  for (final extension in ['.jpg', '.jpeg', '.png', '.webp']) {
    if (lowerName.endsWith(extension)) return extension;
  }
  return switch (mimeType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => '.jpg',
  };
}

String _contentTypeFor(String extension) {
  return switch (extension.toLowerCase()) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}

BoxDecoration _registerCardDecoration({required double radius}) {
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
