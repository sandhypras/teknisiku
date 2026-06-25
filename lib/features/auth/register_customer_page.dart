import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';

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
  final _addressController = TextEditingController();
  late final AuthService _authService;
  late final MarketplaceRepository _repo;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _authService = AuthService(client);
    _repo = MarketplaceRepository(client);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.registerCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await _repo.addAddress(
        label: 'Rumah',
        recipientName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        fullAddress: _addressController.text.trim(),
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
    return _RegisterScaffold(
      title: 'Buat akun customer',
      subtitle: 'Simpan alamat awal agar bisa langsung memesan teknisi.',
      error: _error,
      loading: _loading,
      formKey: _formKey,
      onSubmit: _submit,
      fields: [
        _TextFieldConfig(_nameController, 'Nama lengkap', Icons.person_outline),
        _TextFieldConfig(
          _emailController,
          'Email',
          Icons.email_outlined,
          keyboard: TextInputType.emailAddress,
        ),
        _TextFieldConfig(
          _passwordController,
          'Password',
          Icons.lock_outline,
          obscure: _obscurePassword,
          suffix: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        _TextFieldConfig(
          _phoneController,
          'Nomor telepon',
          Icons.phone_outlined,
          keyboard: TextInputType.phone,
        ),
        _TextFieldConfig(
          _addressController,
          'Alamat lengkap',
          Icons.location_on_outlined,
          maxLines: 3,
        ),
      ],
    );
  }
}

class _RegisterScaffold extends StatelessWidget {
  const _RegisterScaffold({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.formKey,
    required this.onSubmit,
    required this.loading,
    this.error,
  });

  final String title;
  final String subtitle;
  final List<_TextFieldConfig> fields;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSubmit;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: formKey,
              child: Column(
                children: [
                  for (final field in fields) ...[
                    TextFormField(
                      controller: field.controller,
                      obscureText: field.obscure,
                      keyboardType: field.keyboard,
                      maxLines: field.obscure ? 1 : field.maxLines,
                      decoration: InputDecoration(
                        labelText: field.label,
                        prefixIcon: Icon(field.icon),
                        suffixIcon: field.suffix,
                        alignLabelWithHint: field.maxLines > 1,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return '${field.label} wajib diisi';
                        if (field.label == 'Email' && !text.contains('@')) {
                          return 'Format email belum sesuai';
                        }
                        if (field.label == 'Password' && text.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (error != null) ...[
                    Text(
                      error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: loading ? null : onSubmit,
                      child: Text(loading ? 'Memproses...' : 'Daftar'),
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
}

class _TextFieldConfig {
  const _TextFieldConfig(
    this.controller,
    this.label,
    this.icon, {
    this.keyboard,
    this.obscure = false,
    this.maxLines = 1,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final int maxLines;
  final Widget? suffix;
}
