import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/widgets/app_feedback.dart';
import 'admin_shell.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  String? _status;

  static const _filters = <(String, String?)>[
    ('Semua', null),
    ('Pending', 'pending'),
    ('Diproses', 'processing'),
    ('Dibayar', 'paid'),
    ('Ditolak', 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final query = Supabase.instance.client
        .from('technician_withdrawals')
        .select(
          'id, amount, bank_name, account_number, account_holder, status, admin_note, requested_at, processed_at, technician:technician_profiles!technician_id(profile:profiles!user_id(full_name, phone))',
        );
    final data = _status == null
        ? await query.order('requested_at', ascending: false).limit(100)
        : await query
              .eq('status', _status!)
              .order('requested_at', ascending: false)
              .limit(100);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _setStatus(
    Map<String, dynamic> row,
    String status, {
    String? note,
  }) async {
    await Supabase.instance.client
        .from('technician_withdrawals')
        .update({
          'status': status,
          'admin_note': note,
          'processed_at': status == 'paid' || status == 'rejected'
              ? DateTime.now().toIso8601String()
              : null,
        })
        .eq('id', row['id'] as String);
    await Supabase.instance.client.rpc(
      'log_admin_action',
      params: {
        'p_action': 'withdrawal_$status',
        'p_entity': 'technician_withdrawals',
        'p_entity_id': row['id'],
        'p_metadata': {'amount': row['amount'], 'bank': row['bank_name']},
      },
    );
    if (!mounted) return;
    AppFeedback.success(
      context,
      title: 'Status diperbarui',
      message: 'Pengajuan penarikan ditandai ${_statusLabel(status)}.',
    );
    setState(() => _future = _fetch());
  }

  Future<void> _askReject(Map<String, dynamic> row) async {
    final note = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AppFeedbackDialog(
        title: const Text('Tolak Penarikan'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Catatan admin',
            hintText: 'Contoh: Nomor rekening tidak valid',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(note.text.trim()),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await _setStatus(row, 'rejected', note: result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Penarikan Teknisi',
            subtitle: 'Pengajuan transfer manual dari saldo teknisi',
            onRefresh: () => setState(() => _future = _fetch()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _filters.map((filter) {
                final selected = _status == filter.$2;
                return ChoiceChip(
                  selected: selected,
                  label: Text(filter.$1),
                  onSelected: (_) => setState(() {
                    _status = filter.$2;
                    _future = _fetch();
                  }),
                );
              }).toList(),
            ),
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
                    onRetry: () => setState(() => _future = _fetch()),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Belum ada pengajuan penarikan',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: rows.length,
                  itemBuilder: (context, index) => _WithdrawalAdminCard(
                    data: rows[index],
                    onCopyAccount: () => _copyAccount(rows[index]),
                    onProcessing: () => _setStatus(rows[index], 'processing'),
                    onPaid: () => _setStatus(rows[index], 'paid'),
                    onReject: () => _askReject(rows[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyAccount(Map<String, dynamic> data) async {
    final text =
        '${data['bank_name']} ${data['account_number']} a.n. ${data['account_holder']}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppFeedback.success(
      context,
      title: 'Rekening disalin',
      message: 'Data rekening siap ditempel untuk transfer manual.',
    );
  }
}

class _WithdrawalAdminCard extends StatelessWidget {
  const _WithdrawalAdminCard({
    required this.data,
    required this.onCopyAccount,
    required this.onProcessing,
    required this.onPaid,
    required this.onReject,
  });

  final Map<String, dynamic> data;
  final VoidCallback onCopyAccount;
  final VoidCallback onProcessing;
  final VoidCallback onPaid;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final technician =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    final status = data['status'] as String? ?? 'pending';
    return AdminDataCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoBlock(
                  title: technician?['full_name'] as String? ?? '-',
                  subtitle:
                      technician?['phone'] as String? ?? 'Telepon belum ada',
                ),
                const SizedBox(height: 10),
                _InfoBlock(
                  title: '${data['bank_name']} - ${data['account_number']}',
                  subtitle: 'a.n. ${data['account_holder']}',
                ),
                const SizedBox(height: 10),
                Text(
                  formatRupiah((data['amount'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                AdminStatusBadge(
                  label: _statusLabel(status),
                  color: _statusColor(status),
                  bg: _statusColor(status).withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: _actions(status)),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: _InfoBlock(
                  title: technician?['full_name'] as String? ?? '-',
                  subtitle:
                      technician?['phone'] as String? ?? 'Telepon belum ada',
                ),
              ),
              Expanded(
                flex: 3,
                child: _InfoBlock(
                  title: '${data['bank_name']} - ${data['account_number']}',
                  subtitle: 'a.n. ${data['account_holder']}',
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatRupiah((data['amount'] as num?)?.toDouble() ?? 0),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AdminStatusBadge(
                label: _statusLabel(status),
                color: _statusColor(status),
                bg: _statusColor(status).withValues(alpha: 0.12),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: _actions(status),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _actions(String status) {
    return [
      IconButton.filledTonal(
        tooltip: 'Salin rekening',
        onPressed: onCopyAccount,
        icon: const Icon(Icons.copy_rounded),
      ),
      if (status == 'pending')
        OutlinedButton(onPressed: onProcessing, child: const Text('Proses')),
      if (status == 'pending' || status == 'processing')
        FilledButton(onPressed: onPaid, child: const Text('Dibayar')),
      if (status != 'paid' && status != 'rejected')
        TextButton(onPressed: onReject, child: const Text('Tolak')),
    ];
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'paid' => 'Dibayar',
  'rejected' => 'Ditolak',
  'processing' => 'Diproses',
  _ => 'Pending',
};

Color _statusColor(String status) => switch (status) {
  'paid' => AppColors.success,
  'rejected' => AppColors.error,
  'processing' => AppColors.primaryBlue,
  _ => AppColors.warning,
};
