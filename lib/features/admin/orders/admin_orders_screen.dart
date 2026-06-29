import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/app_feedback.dart';
import '../admin_shell.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _selectedStatus;

  static const _statusOptions = <(String, String?)>[
    ('Semua', null),
    ('Menunggu', 'waiting_confirmation'),
    ('Diterima', 'accepted'),
    ('Di Jalan', 'on_the_way'),
    ('Inspeksi', 'inspection'),
    ('Tunggu Biaya', 'waiting_price_approval'),
    ('Dikerjakan', 'in_progress'),
    ('Tunggu Bayar', 'waiting_payment'),
    ('Selesai', 'completed'),
    ('Ditolak', 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _fetch(null);
  }

  Future<List<Map<String, dynamic>>> _fetch(String? status) async {
    final q = Supabase.instance.client
        .from('orders')
        .select(
          'id, order_number, status, schedule_date, schedule_time, problem_description, estimated_total, final_total, commission_percentage, commission_amount, technician_income, created_at, customer:profiles!customer_id(full_name, phone), address:customer_addresses!address_id(full_address, city), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
        );
    final data = status != null
        ? await q
              .eq('status', status)
              .order('created_at', ascending: false)
              .limit(50)
        : await q.order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _updateOrder(
    String id, {
    required String status,
    required double finalTotal,
    required double commissionPercentage,
  }) async {
    await Supabase.instance.client
        .from('orders')
        .update({
          'status': status,
          'final_total': finalTotal,
          'commission_percentage': commissionPercentage,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch(_selectedStatus);
    });
  }

  Future<void> _deleteOrder(String id) async {
    await Supabase.instance.client.from('orders').delete().eq('id', id);
    setState(() {
      _future = _fetch(_selectedStatus);
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
            title: 'Pesanan',
            subtitle: 'Pantau semua pesanan',
            onRefresh: () => setState(() {
              _future = _fetch(_selectedStatus);
            }),
          ),
          _FilterBar(
            options: _statusOptions,
            selected: _selectedStatus,
            onSelect: (v) => setState(() {
              _selectedStatus = v;
              _future = _fetch(v);
            }),
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
                  return const AdminEmptyState(message: 'Tidak ada pesanan');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _OrderCard(
                    data: list[i],
                    onDetail: () => _showOrderDetail(list[i]),
                    onEdit: () => _showOrderEdit(list[i]),
                    onDelete: () => _confirmDeleteOrder(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> data) {
    final customer = data['customer'] as Map<String, dynamic>?;
    final address = data['address'] as Map<String, dynamic>?;
    final techProfile =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (_) => AppFeedbackDialog(
        title: Text(data['order_number'] as String? ?? 'Detail Order'),
        content: SizedBox(
          width: 580,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine('Customer', '${customer?['full_name'] ?? '-'}'),
              _DetailLine('Telepon', '${customer?['phone'] ?? '-'}'),
              _DetailLine('Teknisi', '${techProfile?['full_name'] ?? '-'}'),
              _DetailLine('Status', data['status'] as String? ?? '-'),
              _DetailLine(
                'Jadwal',
                '${data['schedule_date'] ?? '-'} ${data['schedule_time'] ?? ''}',
              ),
              _DetailLine(
                'Alamat',
                '${address?['full_address'] ?? '-'}, ${address?['city'] ?? '-'}',
              ),
              _DetailLine(
                'Estimasi',
                _OrderCard._fmt(
                  (data['estimated_total'] as num?)?.toDouble() ?? 0,
                ),
              ),
              _DetailLine(
                'Total',
                _OrderCard._fmt((data['final_total'] as num?)?.toDouble() ?? 0),
              ),
              const Divider(height: 24),
              Text(
                data['problem_description'] as String? ?? 'Tidak ada deskripsi',
              ),
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

  void _showOrderEdit(Map<String, dynamic> data) {
    var status = data['status'] as String? ?? 'waiting_confirmation';
    final totalCtrl = TextEditingController(
      text: '${(data['final_total'] as num?)?.toDouble() ?? 0}',
    );
    final commissionCtrl = TextEditingController(
      text: '${(data['commission_percentage'] as num?)?.toDouble() ?? 10}',
    );
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AppFeedbackDialog(
          title: Text('Edit ${data['order_number'] ?? 'Order'}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status order'),
                  items: _statusOptions
                      .where((item) => item.$2 != null)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.$2,
                          child: Text(item.$1),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setS(() => status = value ?? status),
                ),
                TextField(
                  controller: totalCtrl,
                  decoration: const InputDecoration(labelText: 'Final total'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: commissionCtrl,
                  decoration: const InputDecoration(labelText: 'Komisi %'),
                  keyboardType: TextInputType.number,
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
                _updateOrder(
                  data['id'] as String,
                  status: status,
                  finalTotal: double.tryParse(totalCtrl.text.trim()) ?? 0,
                  commissionPercentage:
                      double.tryParse(commissionCtrl.text.trim()) ?? 10,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteOrder(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AppFeedbackDialog(
        title: const Text('Hapus Order'),
        content: Text('Hapus order ${data['order_number'] ?? ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOrder(data['id'] as String);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(String, String?)> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, value) = options[i];
          final isSelected = selected == value;
          return GestureDetector(
            onTap: () => onSelect(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.data,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });
  final Map<String, dynamic> data;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? '';
    final badge = _badge(status);
    final customer = data['customer'] as Map<String, dynamic>?;
    final techProfile =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    final finalTotal = (data['final_total'] as num?)?.toDouble() ?? 0;
    final commission = (data['commission_amount'] as num?)?.toDouble() ?? 0;
    final techIncome = (data['technician_income'] as num?)?.toDouble() ?? 0;

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
                Expanded(
                  child: Text(
                    data['order_number'] as String? ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badge.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: badge.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.person_rounded,
                    text: 'Customer: ${customer?['full_name'] ?? '-'}',
                  ),
                ),
                Expanded(
                  child: _InfoRow(
                    icon: Icons.engineering_rounded,
                    text: 'Teknisi: ${techProfile?['full_name'] ?? '-'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              text:
                  'Jadwal: ${data['schedule_date'] ?? '-'} ${data['schedule_time'] ?? ''}',
            ),
            if (finalTotal > 0 && commission > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(child: _MiniStat('Total', _fmt(finalTotal))),
                    Expanded(child: _MiniStat('Komisi', _fmt(commission))),
                    Expanded(child: _MiniStat('Teknisi', _fmt(techIncome))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BadgeStyle _badge(String status) => switch (status) {
    'waiting_confirmation' => _BadgeStyle(
      'Menunggu',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.1),
    ),
    'accepted' => _BadgeStyle(
      'Diterima',
      AppColors.teal,
      AppColors.teal.withValues(alpha: 0.1),
    ),
    'on_the_way' => _BadgeStyle(
      'Di Jalan',
      AppColors.teal,
      AppColors.teal.withValues(alpha: 0.1),
    ),
    'inspection' => _BadgeStyle(
      'Inspeksi',
      const Color(0xFF8B5CF6),
      const Color(0xFF8B5CF6).withValues(alpha: 0.1),
    ),
    'waiting_price_approval' => _BadgeStyle(
      'Tunggu Biaya',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.1),
    ),
    'in_progress' => _BadgeStyle(
      'Dikerjakan',
      AppColors.primary,
      AppColors.primary.withValues(alpha: 0.1),
    ),
    'waiting_payment' => _BadgeStyle(
      'Tunggu Bayar',
      AppColors.amber,
      AppColors.amber.withValues(alpha: 0.15),
    ),
    'completed' => _BadgeStyle(
      'Selesai',
      AppColors.success,
      AppColors.success.withValues(alpha: 0.1),
    ),
    'rejected' || 'price_rejected' => _BadgeStyle(
      'Ditolak',
      AppColors.error,
      AppColors.error.withValues(alpha: 0.1),
    ),
    _ => _BadgeStyle(
      'Unknown',
      AppColors.textSecondary,
      AppColors.textSecondary.withValues(alpha: 0.1),
    ),
  };

  static String _fmt(double v) => v == 0
      ? '-'
      : 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
