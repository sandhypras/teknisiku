import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_shell.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchCtrl = TextEditingController();
  String _search = '';
  List<Map<String, dynamic>> _allCustomers = [];

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _searchCtrl.addListener(() {
      if (_search != _searchCtrl.text) {
        setState(() => _search = _searchCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, email, phone, is_active, created_at')
        .eq('role', 'customer')
        .order('created_at', ascending: false)
        .limit(100);
    _allCustomers = List<Map<String, dynamic>>.from(data);
    return _allCustomers;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _allCustomers;
    final q = _search.trim().toLowerCase();
    return _allCustomers
        .where(
          (c) =>
              (c['full_name'] as String? ?? '').toLowerCase().contains(q) ||
              (c['email'] as String? ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _toggleActive(String userId, bool currentActive) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'is_active': !currentActive})
        .eq('id', userId);
    setState(() {
      _future = _fetch();
    });
  }

  Future<void> _updateCustomer(
    String id, {
    required String fullName,
    required String email,
    required String phone,
    required bool isActive,
  }) async {
    await Supabase.instance.client
        .from('profiles')
        .update({
          'full_name': fullName,
          'email': email,
          'phone': phone.trim().isEmpty ? null : phone.trim(),
          'is_active': isActive,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch();
    });
  }

  Future<void> _deleteCustomer(String id) async {
    await Supabase.instance.client.from('profiles').delete().eq('id', id);
    setState(() {
      _future = _fetch();
    });
  }

  Future<Map<String, dynamic>> _customerDetail(String id) async {
    final results = await Future.wait([
      Supabase.instance.client
          .from('customer_addresses')
          .select(
            'label, recipient_name, phone, full_address, city, is_primary',
          )
          .eq('customer_id', id)
          .order('is_primary', ascending: false),
      Supabase.instance.client
          .from('orders')
          .select(
            'order_number, status, schedule_date, estimated_total, final_total',
          )
          .eq('customer_id', id)
          .order('created_at', ascending: false)
          .limit(8),
    ]);
    return {
      'addresses': List<Map<String, dynamic>>.from(results[0] as List),
      'orders': List<Map<String, dynamic>>.from(results[1] as List),
    };
  }

  void _showDetail(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(customer['full_name'] as String? ?? 'Detail Customer'),
        content: SizedBox(
          width: 620,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _customerDetail(customer['id'] as String),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final addresses =
                  snapshot.data?['addresses'] as List<Map<String, dynamic>>? ??
                  [];
              final orders =
                  snapshot.data?['orders'] as List<Map<String, dynamic>>? ?? [];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailLine('Email', customer['email'] as String? ?? '-'),
                  _DetailLine('Telepon', customer['phone'] as String? ?? '-'),
                  _DetailLine(
                    'Status',
                    (customer['is_active'] as bool? ?? true)
                        ? 'Aktif'
                        : 'Nonaktif',
                  ),
                  const Divider(height: 26),
                  const Text(
                    'Alamat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (addresses.isEmpty)
                    const Text('Belum ada alamat')
                  else
                    ...addresses.map(
                      (item) => Text(
                        '${item['label'] ?? 'Alamat'} - ${item['full_address'] ?? '-'}, ${item['city'] ?? '-'}',
                      ),
                    ),
                  const Divider(height: 26),
                  const Text(
                    'Order Terakhir',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (orders.isEmpty)
                    const Text('Belum ada order')
                  else
                    ...orders.map(
                      (item) => Text(
                        '${item['order_number'] ?? '-'} - ${item['status'] ?? '-'} - ${_formatMoney((item['final_total'] as num?)?.toDouble() ?? (item['estimated_total'] as num?)?.toDouble() ?? 0)}',
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> customer) {
    final nameCtrl = TextEditingController(
      text: customer['full_name'] as String? ?? '',
    );
    final emailCtrl = TextEditingController(
      text: customer['email'] as String? ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: customer['phone'] as String? ?? '',
    );
    var isActive = customer['is_active'] as bool? ?? true;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Edit Customer'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                SwitchListTile(
                  value: isActive,
                  onChanged: (value) => setS(() => isActive = value),
                  title: const Text('Akun aktif'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _updateCustomer(
                  customer['id'] as String,
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  isActive: isActive,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Customer'),
        content: Text(
          'Hapus ${(customer['full_name'] as String?) ?? 'customer'} dari database?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCustomer(customer['id'] as String);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Customer',
            subtitle: 'Kelola data customer',
            onRefresh: () => setState(() {
              _future = _fetch();
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = _filtered;
                if (list.isEmpty) {
                  return const AdminEmptyState(message: 'Tidak ada customer');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _CustomerCard(
                    data: list[i],
                    onDetail: () => _showDetail(list[i]),
                    onEdit: () => _showEditDialog(list[i]),
                    onDelete: () => _confirmDelete(list[i]),
                    onToggleActive: () => _toggleActive(
                      list[i]['id'] as String,
                      list[i]['is_active'] as bool? ?? true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.data,
    required this.onToggleActive,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> data;
  final VoidCallback onToggleActive;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = data['is_active'] as bool? ?? true;
    final name = data['full_name'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isActive ? AppColors.primary : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    data['email'] as String? ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if ((data['phone'] as String?)?.isNotEmpty == true)
                    Text(
                      data['phone'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onToggleActive,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                      color: isActive ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  onSelected: (value) {
                    if (value == 'detail') onDetail();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'detail', child: Text('Detail')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(double amount) {
  if (amount <= 0) return '-';
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
