import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../../shared/widgets/app_feedback.dart';

class TechnicianWithdrawalPage extends StatefulWidget {
  const TechnicianWithdrawalPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<TechnicianWithdrawalPage> createState() =>
      _TechnicianWithdrawalPageState();
}

class _TechnicianWithdrawalPageState extends State<TechnicianWithdrawalPage> {
  late Future<_WithdrawalData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WithdrawalData> _load() async {
    final technician = await widget.repo.myTechnicianProfile();
    if (technician == null) {
      return const _WithdrawalData(
        technician: null,
        balance: 0,
        withdrawals: [],
      );
    }
    final results = await Future.wait<Object>([
      widget.repo.technicianWithdrawableBalance(technician.id),
      widget.repo.technicianWithdrawals(technician.id),
    ]);
    return _WithdrawalData(
      technician: technician,
      balance: results[0] as double,
      withdrawals: results[1] as List<WithdrawalRequest>,
    );
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F8FF), Color(0xFFFAFCFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_WithdrawalData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: friendlyErrorMessage(snapshot.error),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  const _Header(),
                  const SizedBox(height: 18),
                  _BalanceCard(
                    balance: data.balance,
                    onWithdraw: data.technician == null
                        ? null
                        : () => _showWithdrawalSheet(data),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Riwayat Penarikan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (data.withdrawals.isEmpty)
                    const EmptyState(message: 'Belum ada pengajuan penarikan')
                  else
                    ...data.withdrawals.map(_WithdrawalCard.new),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showWithdrawalSheet(_WithdrawalData data) {
    final amount = TextEditingController();
    final bank = TextEditingController();
    final account = TextEditingController();
    final holder = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var loading = false;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            final value =
                double.tryParse(amount.text.replaceAll('.', '').trim()) ?? 0;
            if (value > data.balance) {
              AppFeedback.warning(
                context,
                title: 'Saldo tidak cukup',
                message: 'Nominal penarikan melebihi saldo tersedia.',
              );
              return;
            }
            setSheetState(() => loading = true);
            try {
              await widget.repo.createWithdrawalRequest(
                technicianId: data.technician!.id,
                amount: value,
                bankName: bank.text,
                accountNumber: account.text,
                accountHolder: holder.text,
              );
              if (!mounted || !sheetContext.mounted) return;
              Navigator.of(sheetContext).pop();
              AppFeedback.success(
                context,
                title: 'Pengajuan dikirim',
                message: 'Admin akan memproses transfer secara manual.',
              );
              _refresh();
            } catch (error) {
              if (!mounted) return;
              AppFeedback.error(
                context,
                title: 'Penarikan gagal',
                message: friendlyErrorMessage(error),
              );
            } finally {
              if (mounted) setSheetState(() => loading = false);
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajukan Penarikan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Saldo tersedia ${formatRupiah(data.balance)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal penarikan',
                        prefixText: 'Rp ',
                      ),
                      validator: (value) {
                        final amount =
                            double.tryParse(
                              (value ?? '').replaceAll('.', '').trim(),
                            ) ??
                            0;
                        if (amount <= 0) return 'Nominal wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bank,
                      decoration: const InputDecoration(labelText: 'Nama bank'),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: account,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor rekening',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: holder,
                      decoration: const InputDecoration(
                        labelText: 'Nama pemilik rekening',
                      ),
                      validator: _required,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: loading ? null : submit,
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          loading ? 'Mengirim...' : 'Kirim Pengajuan',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Penarikan Saldo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Ajukan pencairan pendapatan ke rekening Anda.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onWithdraw});

  final double balance;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo dapat ditarik',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: balance <= 0 ? null : onWithdraw,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: const Text('Tarik Saldo'),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard(this.item);

  final WithdrawalRequest item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupiah(item.amount),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(item.status),
              ],
            ),
            const SizedBox(height: 10),
            Text('${item.bankName} - ${item.accountNumber}'),
            Text(
              item.accountHolder,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if ((item.adminNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                item.adminNote!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => AppColors.success,
      'rejected' => AppColors.danger,
      'processing' => AppColors.secondary,
      _ => AppColors.warning,
    };
    final label = switch (status) {
      'paid' => 'Dibayar',
      'rejected' => 'Ditolak',
      'processing' => 'Diproses',
      _ => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WithdrawalData {
  const _WithdrawalData({
    required this.technician,
    required this.balance,
    required this.withdrawals,
  });

  final TechnicianSummary? technician;
  final double balance;
  final List<WithdrawalRequest> withdrawals;
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return 'Wajib diisi';
  return null;
}
