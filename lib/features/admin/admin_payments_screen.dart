import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/widgets/app_feedback.dart';
import 'admin_shell.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _selectedStatus;

  static const _filters = <(String, String?)>[
    ('Semua', null),
    ('Belum Bayar', 'unpaid'),
    ('Verifikasi', 'waiting_verification'),
    ('Paid', 'paid'),
    ('Rejected', 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _fetch(null);
  }

  Future<List<Map<String, dynamic>>> _fetch(String? status) async {
    final q = Supabase.instance.client
        .from('payments')
        .select(
          'id, payment_method, amount, proof_url, payment_status, paid_at, created_at, midtrans_order_id, transaction_id, fraud_status, snap_redirect_url, order:orders!order_id(order_number, customer:profiles!customer_id(full_name), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name)))',
        );
    final data = status == null
        ? await q.order('created_at', ascending: false).limit(80)
        : await q
              .eq('payment_status', status)
              .order('created_at', ascending: false)
              .limit(80);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _setStatus(String id, String status) async {
    await Supabase.instance.client
        .from('payments')
        .update({
          'payment_status': status,
          'paid_at': status == 'paid' ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch(_selectedStatus);
    });
  }

  Future<void> _updatePayment(
    String id, {
    required String status,
    required String method,
    required double amount,
  }) async {
    await Supabase.instance.client
        .from('payments')
        .update({
          'payment_status': status,
          'payment_method': method,
          'amount': amount,
          'paid_at': status == 'paid' ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch(_selectedStatus);
    });
  }

  Future<void> _deletePayment(String id) async {
    await Supabase.instance.client.from('payments').delete().eq('id', id);
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
            title: 'Pembayaran',
            subtitle: 'Verifikasi pembayaran customer',
            onRefresh: () => setState(() {
              _future = _fetch(_selectedStatus);
            }),
          ),
          _FilterBar(
            options: _filters,
            selected: _selectedStatus,
            onSelect: (value) => setState(() {
              _selectedStatus = value;
              _future = _fetch(value);
            }),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AdminErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _future = _fetch(_selectedStatus);
                    }),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const AdminEmptyState(message: 'Tidak ada pembayaran');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _PaymentCard(
                    data: rows[i],
                    onApprove: () =>
                        _setStatus(rows[i]['id'] as String, 'paid'),
                    onReject: () =>
                        _setStatus(rows[i]['id'] as String, 'rejected'),
                    onDetail: () => _showPaymentDetail(rows[i]),
                    onEdit: () => _showPaymentEdit(rows[i]),
                    onDelete: () => _confirmDeletePayment(rows[i]),
                    onProof: () => _showPaymentProof(rows[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetail(Map<String, dynamic> data) {
    final order = data['order'] as Map<String, dynamic>?;
    final customer = order?['customer'] as Map<String, dynamic>?;
    final technician =
        (order?['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (_) => AppFeedbackDialog(
        title: Text(order?['order_number'] as String? ?? 'Detail Pembayaran'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine('Customer', '${customer?['full_name'] ?? '-'}'),
              _DetailLine('Teknisi', '${technician?['full_name'] ?? '-'}'),
              _DetailLine(
                'Metode',
                _methodLabel(data['payment_method'] as String?),
              ),
              _DetailLine('Status', data['payment_status'] as String? ?? '-'),
              _DetailLine(
                'Midtrans Order ID',
                data['midtrans_order_id'] as String? ?? '-',
              ),
              _DetailLine(
                'Transaction ID',
                data['transaction_id'] as String? ?? '-',
              ),
              _DetailLine('Fraud', data['fraud_status'] as String? ?? '-'),
              _DetailLine(
                'Amount',
                formatRupiah((data['amount'] as num?)?.toDouble() ?? 0),
              ),
              _DetailLine('Dibayar', data['paid_at'] as String? ?? '-'),
            ],
          ),
        ),
        actions: [
          if ((data['proof_url'] as String?)?.isNotEmpty == true)
            TextButton(
              onPressed: () => _showPaymentProof(data),
              child: const Text('Lihat Bukti'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showPaymentEdit(Map<String, dynamic> data) {
    var status = data['payment_status'] as String? ?? 'unpaid';
    var method = data['payment_method'] as String? ?? 'cash';
    final amountCtrl = TextEditingController(
      text: '${(data['amount'] as num?)?.toDouble() ?? 0}',
    );
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AppFeedbackDialog(
          title: const Text('Edit Pembayaran'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Metode'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(
                      value: 'bank_transfer',
                      child: Text('Transfer Bank'),
                    ),
                  ],
                  onChanged: (value) => setS(() => method = value ?? method),
                ),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                    DropdownMenuItem(
                      value: 'waiting_verification',
                      child: Text('Verifikasi'),
                    ),
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
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
                _updatePayment(
                  data['id'] as String,
                  status: status,
                  method: method,
                  amount: double.tryParse(amountCtrl.text.trim()) ?? 0,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentProof(Map<String, dynamic> data) async {
    final proof = data['proof_url'] as String? ?? '';
    if (proof.isEmpty) return;
    final path = proof.replaceFirst('payment-proofs/', '');
    showDialog(
      context: context,
      builder: (_) => AppFeedbackDialog(
        title: const Text('Bukti Pembayaran'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: FutureBuilder<String>(
            future: proof.startsWith('http')
                ? Future.value(proof)
                : Supabase.instance.client.storage
                      .from('payment-proofs')
                      .createSignedUrl(path, 600),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              return Image.network(
                snapshot.data!,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Gagal memuat bukti')),
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

  void _confirmDeletePayment(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AppFeedbackDialog(
        title: const Text('Hapus Pembayaran'),
        content: const Text('Hapus data pembayaran ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePayment(data['id'] as String);
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
      height: 46,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, value) = options[i];
          final active = selected == value;
          return ChoiceChip(
            label: Text(label),
            selected: active,
            onSelected: (_) => onSelect(value),
            selectedColor: AppColors.iconBg,
            labelStyle: TextStyle(
              color: active ? AppColors.primaryBlue : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
            side: const BorderSide(color: AppColors.border),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
    required this.onProof,
  });

  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onProof;

  @override
  Widget build(BuildContext context) {
    final order = data['order'] as Map<String, dynamic>?;
    final customer = order?['customer'] as Map<String, dynamic>?;
    final technician =
        (order?['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    final status = data['payment_status'] as String? ?? 'unpaid';
    final badge = _paymentBadge(status);

    return AdminDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBox(icon: Icons.payment_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order?['order_number'] as String? ?? '-',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${customer?['full_name'] ?? '-'} -> ${technician?['full_name'] ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AdminStatusBadge(
                label: badge.label,
                color: badge.color,
                bg: badge.bg,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'detail') onDetail();
                  if (value == 'edit') onEdit();
                  if (value == 'proof') onProof();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'detail', child: Text('Detail')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'proof', child: Text('Lihat Bukti')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminInfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label: formatRupiah((data['amount'] as num?)?.toDouble() ?? 0),
              ),
              AdminInfoChip(
                icon: Icons.credit_card_rounded,
                label: _methodLabel(data['payment_method'] as String?),
              ),
              if ((data['midtrans_order_id'] as String?)?.isNotEmpty == true)
                const AdminInfoChip(
                  icon: Icons.verified_rounded,
                  label: 'Midtrans Sandbox',
                ),
              if ((data['proof_url'] as String?)?.isNotEmpty == true)
                const AdminInfoChip(
                  icon: Icons.attachment_rounded,
                  label: 'Bukti tersedia',
                ),
            ],
          ),
          if (status == 'waiting_verification') ...[
            const SizedBox(height: 14),
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
                    label: const Text('Konfirmasi'),
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

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.iconBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primaryBlue, size: 20),
    );
  }
}

_Badge _paymentBadge(String status) => switch (status) {
  'waiting_verification' => _Badge(
    'Verifikasi',
    AppColors.warning,
    AppColors.warning.withValues(alpha: 0.12),
  ),
  'paid' => _Badge(
    'Paid',
    AppColors.success,
    AppColors.success.withValues(alpha: 0.12),
  ),
  'rejected' => _Badge(
    'Rejected',
    AppColors.error,
    AppColors.error.withValues(alpha: 0.12),
  ),
  _ => _Badge(
    'Unpaid',
    AppColors.textSecondary,
    AppColors.textSecondary.withValues(alpha: 0.12),
  ),
};

String _methodLabel(String? method) => switch (method) {
  'bank_transfer' => 'Transfer Bank',
  'cash' => 'Cash',
  _ => '-',
};

class _Badge {
  const _Badge(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}
