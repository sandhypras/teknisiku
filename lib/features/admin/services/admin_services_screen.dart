import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_shell.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _future;

  final _tabs = const ['Semua', 'Pending', 'Approved', 'Rejected'];
  final _filters = [null, 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(
      () => setState(() {
        _future = _fetch(_filters[_tabController.index]);
      }),
    );
    _future = _fetch(null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch(String? status) async {
    final q = Supabase.instance.client
        .from('services')
        .select(
          'id, name, description, estimated_price, estimated_duration, approval_status, is_active, created_at, category:categories(name), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
        );
    final data = status != null
        ? await q
              .eq('approval_status', status)
              .order('created_at', ascending: false)
        : await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _updateStatus(String id, String status, {String? reason}) async {
    await Supabase.instance.client
        .from('services')
        .update({'approval_status': status, 'rejection_reason': ?reason})
        .eq('id', id);
    setState(() {
      _future = _fetch(_filters[_tabController.index]);
    });
  }

  Future<void> _updateService(
    String id, {
    required String name,
    required String description,
    required double price,
    required String duration,
    required bool isActive,
    required String status,
  }) async {
    await Supabase.instance.client
        .from('services')
        .update({
          'name': name,
          'description': description.trim().isEmpty ? null : description.trim(),
          'estimated_price': price,
          'estimated_duration': duration.trim().isEmpty
              ? null
              : duration.trim(),
          'is_active': isActive,
          'approval_status': status,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch(_filters[_tabController.index]);
    });
  }

  Future<void> _deleteService(String id) async {
    await Supabase.instance.client.from('services').delete().eq('id', id);
    setState(() {
      _future = _fetch(_filters[_tabController.index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Layanan',
            subtitle: 'Kelola persetujuan layanan teknisi',
            onRefresh: () => setState(
              () => _future = _fetch(_filters[_tabController.index]),
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const AdminEmptyState(message: 'Tidak ada layanan');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _ServiceCard(
                    data: list[i],
                    onApprove: () =>
                        _updateStatus(list[i]['id'] as String, 'approved'),
                    onReject: () =>
                        _showRejectDialog(context, list[i]['id'] as String),
                    onDetail: () => _showServiceDetail(list[i]),
                    onEdit: () => _showServiceEdit(list[i]),
                    onDelete: () => _confirmDeleteService(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Layanan'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, 'rejected', reason: ctrl.text);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  void _showServiceDetail(Map<String, dynamic> data) {
    final category = data['category'] as Map<String, dynamic>?;
    final techProfile =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['name'] as String? ?? 'Detail Layanan'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine('Kategori', '${category?['name'] ?? '-'}'),
              _DetailLine('Teknisi', '${techProfile?['full_name'] ?? '-'}'),
              _DetailLine(
                'Harga',
                _ServiceCard._formatCurrency(
                  (data['estimated_price'] as num?)?.toDouble() ?? 0,
                ),
              ),
              _DetailLine(
                'Durasi',
                data['estimated_duration'] as String? ?? '-',
              ),
              _DetailLine('Status', data['approval_status'] as String? ?? '-'),
              _DetailLine(
                'Aktif',
                (data['is_active'] as bool? ?? true) ? 'Ya' : 'Tidak',
              ),
              const Divider(height: 24),
              Text(data['description'] as String? ?? 'Tidak ada deskripsi'),
            ],
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

  void _showServiceEdit(Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name'] as String? ?? '');
    final descCtrl = TextEditingController(
      text: data['description'] as String? ?? '',
    );
    final priceCtrl = TextEditingController(
      text: '${(data['estimated_price'] as num?)?.toDouble() ?? 0}',
    );
    final durationCtrl = TextEditingController(
      text: data['estimated_duration'] as String? ?? '',
    );
    var isActive = data['is_active'] as bool? ?? true;
    var status = data['approval_status'] as String? ?? 'pending';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Edit Layanan'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama layanan'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(labelText: 'Durasi'),
                ),
                SwitchListTile(
                  value: isActive,
                  onChanged: (v) => setS(() => isActive = v),
                  title: const Text('Aktif'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Approval'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) => setS(() => status = value ?? status),
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
                _updateService(
                  data['id'] as String,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text,
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                  duration: durationCtrl.text,
                  isActive: isActive,
                  status: status,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteService(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text('Hapus layanan ${data['name'] ?? ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteService(data['id'] as String);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = data['approval_status'] as String? ?? '';
    final badge = _badge(status);
    final category = data['category'] as Map<String, dynamic>?;
    final techProfile =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    final price = (data['estimated_price'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] as String? ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${category?['name'] ?? '-'} • ${techProfile?['full_name'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: badge.label,
                  color: badge.color,
                  bg: badge.bg,
                ),
                PopupMenuButton<String>(
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
            if ((data['description'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                data['description'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.attach_money_rounded,
                  label: _formatCurrency(price),
                ),
                if ((data['estimated_duration'] as String?)?.isNotEmpty ==
                    true) ...[
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: data['estimated_duration'] as String,
                  ),
                ],
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Setujui'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BadgeStyle _badge(String status) => switch (status) {
    'pending' => _BadgeStyle(
      'Pending',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.12),
    ),
    'approved' => _BadgeStyle(
      'Approved',
      AppColors.success,
      AppColors.success.withValues(alpha: 0.12),
    ),
    'rejected' => _BadgeStyle(
      'Rejected',
      AppColors.error,
      AppColors.error.withValues(alpha: 0.12),
    ),
    _ => _BadgeStyle(
      'Unknown',
      AppColors.textSecondary,
      AppColors.textSecondary.withValues(alpha: 0.1),
    ),
  };

  static String _formatCurrency(double amount) =>
      'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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

class _BadgeStyle {
  const _BadgeStyle(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
