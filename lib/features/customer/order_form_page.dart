import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({
    required this.technician,
    required this.services,
    super.key,
  });

  final TechnicianSummary technician;
  final List<TechnicianService> services;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _problem = TextEditingController();
  final _time = TextEditingController(text: '09:00');
  late final MarketplaceRepository _repo;
  late Future<List<CustomerAddress>> _addressesFuture;
  CustomerAddress? _selectedAddress;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repo = MarketplaceRepository(Supabase.instance.client);
    _addressesFuture = _repo.customerAddresses();
  }

  @override
  void dispose() {
    _problem.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih alamat terlebih dahulu')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _repo.createOrder(
        technician: widget.technician,
        services: widget.services,
        address: _selectedAddress!,
        scheduleDate: _date,
        scheduleTime: _time.text.trim(),
        problemDescription: _problem.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.services.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Form Pemesanan')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.technician.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final service in widget.services)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(service.name)),
                            Text(formatRupiah(service.price)),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Estimasi total',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          formatRupiah(total),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<CustomerAddress>>(
                future: _addressesFuture,
                builder: (context, snapshot) {
                  final addresses = snapshot.data ?? [];
                  _selectedAddress ??=
                      addresses.where((item) => item.isPrimary).firstOrNull ??
                      addresses.firstOrNull;
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (addresses.isEmpty) {
                    return const EmptyState(
                      message: 'Belum ada alamat. Lengkapi alamat saat daftar.',
                    );
                  }
                  return DropdownButtonFormField<CustomerAddress>(
                    initialValue: _selectedAddress,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: addresses
                        .map(
                          (address) => DropdownMenuItem(
                            value: address,
                            child: Text(
                              '${address.label} - ${address.fullAddress}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAddress = value),
                  );
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _problem,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi kerusakan',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.report_problem_outlined),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 45),
                          ),
                          initialDate: _date,
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(_date.toIso8601String().split('T').first),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _time,
                      decoration: const InputDecoration(
                        labelText: 'Jam',
                        prefixIcon: Icon(Icons.schedule_rounded),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Jam wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(_loading ? 'Mengirim...' : 'Kirim Pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
