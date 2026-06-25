import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

class AdminCommissionScreen extends StatefulWidget {
  const AdminCommissionScreen({super.key});

  @override
  State<AdminCommissionScreen> createState() => _AdminCommissionScreenState();
}

class _AdminCommissionScreenState extends State<AdminCommissionScreen> {
  late Future<_CommissionData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_CommissionData> _fetch() async {
    final db = Supabase.instance.client;
    final results = await Future.wait([
      db
          .from('orders')
          .select(
            'order_number, final_total, commission_percentage, commission_amount, technician_income, created_at, technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
          )
          .gt('final_total', 0)
          .order('created_at', ascending: false)
          .limit(100),
      db
          .from('app_settings')
          .select('value')
          .eq('key', 'commission_percentage')
          .maybeSingle(),
    ]);

    final orders = List<Map<String, dynamic>>.from(results[0] as List);
    final setting = results[1] as Map<String, dynamic>?;
    return _CommissionData(
      orders: orders,
      defaultPercentage: double.tryParse('${setting?['value'] ?? '10'}') ?? 10,
      gross: orders.fold<double>(
        0.0,
        (sum, row) => sum + ((row['final_total'] as num?)?.toDouble() ?? 0),
      ),
      commission: orders.fold<double>(
        0.0,
        (sum, row) =>
            sum + ((row['commission_amount'] as num?)?.toDouble() ?? 0),
      ),
      technicianIncome: orders.fold<double>(
        0.0,
        (sum, row) =>
            sum + ((row['technician_income'] as num?)?.toDouble() ?? 0),
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
            title: 'Komisi',
            subtitle: 'Rekap komisi platform dari order',
            onRefresh: () => setState(() => _future = _fetch()),
          ),
          Expanded(
            child: FutureBuilder<_CommissionData>(
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
                final data = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        AdminMetricTile(
                          label: 'Default Komisi',
                          value:
                              '${data.defaultPercentage.toStringAsFixed(0)}%',
                          icon: Icons.percent_rounded,
                          color: AppColors.primaryBlue,
                        ),
                        AdminMetricTile(
                          label: 'Omzet Order',
                          value: formatRupiah(data.gross),
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.teal,
                        ),
                        AdminMetricTile(
                          label: 'Komisi Platform',
                          value: formatRupiah(data.commission),
                          icon: Icons.savings_outlined,
                          color: AppColors.success,
                        ),
                        AdminMetricTile(
                          label: 'Pendapatan Teknisi',
                          value: formatRupiah(data.technicianIncome),
                          icon: Icons.engineering_rounded,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (data.orders.isEmpty)
                      const SizedBox(
                        height: 320,
                        child: AdminEmptyState(message: 'Belum ada komisi'),
                      )
                    else
                      ...data.orders.map((row) => _CommissionRow(data: row)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionRow extends StatelessWidget {
  const _CommissionRow({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final technician =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    return AdminDataCard(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              data['order_number'] as String? ?? '-',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              technician?['full_name'] as String? ?? '-',
              style: const TextStyle(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${((data['commission_percentage'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              formatRupiah(
                (data['commission_amount'] as num?)?.toDouble() ?? 0,
              ),
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommissionData {
  const _CommissionData({
    required this.orders,
    required this.defaultPercentage,
    required this.gross,
    required this.commission,
    required this.technicianIncome,
  });

  final List<Map<String, dynamic>> orders;
  final double defaultPercentage;
  final double gross;
  final double commission;
  final double technicianIncome;
}
