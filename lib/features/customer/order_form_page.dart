import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/location_service.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../../shared/widgets/app_feedback.dart';

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
  final _label = TextEditingController(text: 'Rumah');
  final _recipient = TextEditingController();
  final _phone = TextEditingController();
  final _fullAddress = TextEditingController();
  final _city = TextEditingController(text: 'Solo');
  final _district = TextEditingController();
  final _village = TextEditingController();
  final _postalCode = TextEditingController();

  late final MarketplaceRepository _repo;
  late Future<List<CustomerAddress>> _addressesFuture;
  CustomerAddress? _selectedAddress;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  double? _latitude;
  double? _longitude;
  bool _loading = false;
  bool _locating = false;
  bool _useSavedAddress = true;

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
    _label.dispose();
    _recipient.dispose();
    _phone.dispose();
    _fullAddress.dispose();
    _city.dispose();
    _district.dispose();
    _village.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final address = await _resolveOrderAddress();
      await _repo.createOrder(
        technician: widget.technician,
        services: widget.services,
        address: address,
        scheduleDate: _date,
        scheduleTime: _time.text.trim(),
        problemDescription: _problem.text.trim(),
      );
      if (!mounted) return;
      AppFeedback.success(
        context,
        title: 'Pesanan dibuat',
        message: 'Pesanan berhasil dikirim ke teknisi.',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        title: 'Pesanan gagal dibuat',
        message: error.toString(),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<CustomerAddress> _resolveOrderAddress() async {
    if (_useSavedAddress) {
      final addresses = await _addressesFuture;
      final savedAddress =
          _selectedAddress ??
          addresses.where((item) => item.isPrimary).firstOrNull ??
          addresses.firstOrNull;
      if (savedAddress != null) return savedAddress;
    }
    return _repo.addAddress(
      label: _label.text.trim(),
      recipientName: _recipient.text.trim(),
      phone: _phone.text.trim(),
      fullAddress: _fullAddress.text.trim(),
      city: _city.text.trim(),
      district: _district.text.trim(),
      village: _village.text.trim(),
      postalCode: _postalCode.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      isPrimary: false,
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final location = await getCurrentAddress();
      setState(() {
        _useSavedAddress = false;
        _latitude = location.latitude;
        _longitude = location.longitude;
        if (_label.text.trim().isEmpty || _label.text == 'Rumah') {
          _label.text = 'Lokasi Saat Ini';
        }
        _fullAddress.text = location.fullAddress;
        _city.text = location.city;
        _district.text = location.district ?? _district.text;
        _village.text = location.village ?? _village.text;
        _postalCode.text = location.postalCode ?? _postalCode.text;
      });
    } catch (error) {
      if (!mounted) return;
      AppFeedback.warning(
        context,
        title: 'Lokasi belum terbaca',
        message: error.toString(),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 45)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final current =
        _parseTime(_time.text) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      setState(() {
        _time.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
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
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              _OrderHero(technician: widget.technician, total: total),
              const SizedBox(height: 14),
              _ServiceSummary(services: widget.services, total: total),
              const SizedBox(height: 14),
              _AddressSection(
                addressesFuture: _addressesFuture,
                selectedAddress: _selectedAddress,
                useSavedAddress: _useSavedAddress,
                locating: _locating,
                latitude: _latitude,
                longitude: _longitude,
                label: _label,
                recipient: _recipient,
                phone: _phone,
                fullAddress: _fullAddress,
                city: _city,
                district: _district,
                village: _village,
                postalCode: _postalCode,
                onAddressSelected: (address) =>
                    setState(() => _selectedAddress = address),
                onModeChanged: (value) =>
                    setState(() => _useSavedAddress = value),
                onUseCurrentLocation: _useCurrentLocation,
              ),
              const SizedBox(height: 14),
              _ScheduleSection(
                date: _date,
                time: _time,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              const SizedBox(height: 14),
              _FormCard(
                title: 'Detail Masalah',
                icon: Icons.build_circle_outlined,
                child: TextFormField(
                  controller: _problem,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi kerusakan',
                    hintText:
                        'Contoh: laptop tidak menyala, pernah jatuh, sudah dicoba charger lain.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.report_problem_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Deskripsi wajib diisi'
                      : null,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _loading || _locating ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
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

class _OrderHero extends StatelessWidget {
  const _OrderHero({required this.technician, required this.total});

  final TechnicianSummary technician;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075AC8), Color(0xFF0B74E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technician.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimasi ${formatRupiah(total)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.services, required this.total});

  final List<TechnicianService> services;
  final double total;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Layanan Dipilih',
      icon: Icons.widgets_outlined,
      child: Column(
        children: [
          for (final service in services) ...[
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    categoryIcon(service.categoryName ?? service.name),
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (service.duration != null)
                        Text(
                          service.duration!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(service.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (service != services.last)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estimasi total',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.addressesFuture,
    required this.selectedAddress,
    required this.useSavedAddress,
    required this.locating,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.fullAddress,
    required this.city,
    required this.district,
    required this.village,
    required this.postalCode,
    required this.onAddressSelected,
    required this.onModeChanged,
    required this.onUseCurrentLocation,
    this.latitude,
    this.longitude,
  });

  final Future<List<CustomerAddress>> addressesFuture;
  final CustomerAddress? selectedAddress;
  final bool useSavedAddress;
  final bool locating;
  final double? latitude;
  final double? longitude;
  final TextEditingController label;
  final TextEditingController recipient;
  final TextEditingController phone;
  final TextEditingController fullAddress;
  final TextEditingController city;
  final TextEditingController district;
  final TextEditingController village;
  final TextEditingController postalCode;
  final ValueChanged<CustomerAddress?> onAddressSelected;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Alamat Layanan',
      icon: Icons.location_on_outlined,
      child: FutureBuilder<List<CustomerAddress>>(
        future: addressesFuture,
        builder: (context, snapshot) {
          final addresses = snapshot.data ?? [];
          final hasSaved = addresses.isNotEmpty;
          final useSaved = hasSaved && useSavedAddress;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasSaved)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.bookmark_outline_rounded),
                      label: Text('Tersimpan'),
                    ),
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.my_location_rounded),
                      label: Text('Baru'),
                    ),
                  ],
                  selected: {useSaved},
                  onSelectionChanged: (values) => onModeChanged(values.first),
                ),
              if (hasSaved) const SizedBox(height: 14),
              if (useSaved)
                DropdownButtonFormField<CustomerAddress>(
                  initialValue:
                      selectedAddress ??
                      addresses.where((item) => item.isPrimary).firstOrNull ??
                      addresses.first,
                  decoration: const InputDecoration(
                    labelText: 'Pilih alamat',
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
                  onChanged: onAddressSelected,
                  validator: (value) =>
                      value == null ? 'Pilih alamat terlebih dahulu' : null,
                )
              else
                _NewAddressFields(
                  locating: locating,
                  latitude: latitude,
                  longitude: longitude,
                  label: label,
                  recipient: recipient,
                  phone: phone,
                  fullAddress: fullAddress,
                  city: city,
                  district: district,
                  village: village,
                  postalCode: postalCode,
                  onUseCurrentLocation: onUseCurrentLocation,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NewAddressFields extends StatelessWidget {
  const _NewAddressFields({
    required this.locating,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.fullAddress,
    required this.city,
    required this.district,
    required this.village,
    required this.postalCode,
    required this.onUseCurrentLocation,
    this.latitude,
    this.longitude,
  });

  final bool locating;
  final double? latitude;
  final double? longitude;
  final TextEditingController label;
  final TextEditingController recipient;
  final TextEditingController phone;
  final TextEditingController fullAddress;
  final TextEditingController city;
  final TextEditingController district;
  final TextEditingController village;
  final TextEditingController postalCode;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: locating ? null : onUseCurrentLocation,
            icon: locating
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              locating ? 'Mengambil lokasi...' : 'Gunakan lokasi saat ini',
            ),
          ),
        ),
        if (latitude != null && longitude != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _RequiredField(
          controller: label,
          label: 'Label alamat',
          icon: Icons.bookmark_outline_rounded,
        ),
        const SizedBox(height: 12),
        _RequiredField(
          controller: recipient,
          label: 'Nama penerima',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _RequiredField(
          controller: phone,
          label: 'Nomor HP',
          icon: Icons.call_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _RequiredField(
          controller: fullAddress,
          label: 'Alamat lengkap',
          icon: Icons.home_work_outlined,
          minLines: 3,
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RequiredField(
                controller: city,
                label: 'Kota',
                icon: Icons.location_city_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: postalCode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kode pos',
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: district,
                decoration: const InputDecoration(
                  labelText: 'Kecamatan',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: village,
                decoration: const InputDecoration(
                  labelText: 'Kelurahan',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime date;
  final TextEditingController time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Jadwal Kunjungan',
      icon: Icons.calendar_month_outlined,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text(_formatDate(date)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: time,
              readOnly: true,
              onTap: onPickTime,
              decoration: const InputDecoration(
                labelText: 'Jam',
                prefixIcon: Icon(Icons.schedule_rounded),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Jam wajib diisi';
                return RegExp(r'^\d{2}:\d{2}$').hasMatch(text)
                    ? null
                    : 'Format jam tidak valid';
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 19),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? '$label wajib diisi' : null,
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

TimeOfDay? _parseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
