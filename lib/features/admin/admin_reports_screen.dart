import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<_ReportData> _fetch() async {
    final db = Supabase.instance.client;
    final results = await Future.wait([
      db.from('orders').select('status, final_total, commission_amount'),
      db.from('payments').select('payment_status, amount'),
      db.from('reviews').select('rating'),
      db
          .from('technician_profiles')
          .select('id')
          .eq('verification_status', 'pending'),
      db.from('services').select('id').eq('approval_status', 'pending'),
    ]);

    final orders = List<Map<String, dynamic>>.from(results[0] as List);
    final payments = List<Map<String, dynamic>>.from(results[1] as List);
    final reviews = List<Map<String, dynamic>>.from(results[2] as List);
    final paidPayments = payments
        .where((row) => row['payment_status'] == 'paid')
        .toList();
    final completed = orders
        .where((row) => row['status'] == 'completed')
        .length;
    final revenue = paidPayments.fold<double>(
      0.0,
      (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
    );
    final commission = orders.fold<double>(
      0.0,
      (sum, row) => sum + ((row['commission_amount'] as num?)?.toDouble() ?? 0),
    );
    final rating = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(
                0.0,
                (sum, row) => sum + ((row['rating'] as num?)?.toDouble() ?? 0),
              ) /
              reviews.length;

    return _ReportData(
      totalOrders: orders.length,
      completedOrders: completed,
      revenue: revenue,
      commission: commission,
      averageRating: rating,
      pendingTechnicians: (results[3] as List).length,
      pendingServices: (results[4] as List).length,
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
            title: 'Laporan',
            subtitle: 'Ringkasan performa operasional',
            onRefresh: () => setState(() => _future = _fetch()),
          ),
          Expanded(
            child: FutureBuilder<_ReportData>(
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
                return GridView.count(
                  padding: const EdgeInsets.all(20),
                  crossAxisCount: MediaQuery.sizeOf(context).width > 1100
                      ? 4
                      : MediaQuery.sizeOf(context).width > 720
                      ? 2
                      : 1,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2.25,
                  children: [
                    AdminMetricTile(
                      label: 'Total Pesanan',
                      value: '${data.totalOrders}',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    AdminMetricTile(
                      label: 'Order Selesai',
                      value: '${data.completedOrders}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                    ),
                    AdminMetricTile(
                      label: 'Pendapatan Paid',
                      value: formatRupiah(data.revenue),
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.teal,
                    ),
                    AdminMetricTile(
                      label: 'Komisi',
                      value: formatRupiah(data.commission),
                      icon: Icons.percent_rounded,
                      color: AppColors.warning,
                    ),
                    AdminMetricTile(
                      label: 'Rating Rata-rata',
                      value: data.averageRating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: AppColors.warning,
                    ),
                    AdminMetricTile(
                      label: 'Teknisi Pending',
                      value: '${data.pendingTechnicians}',
                      icon: Icons.person_search_rounded,
                      color: AppColors.error,
                    ),
                    AdminMetricTile(
                      label: 'Layanan Pending',
                      value: '${data.pendingServices}',
                      icon: Icons.build_circle_rounded,
                      color: AppColors.primaryBlue,
                    ),
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

class _ReportData {
  const _ReportData({
    required this.totalOrders,
    required this.completedOrders,
    required this.revenue,
    required this.commission,
    required this.averageRating,
    required this.pendingTechnicians,
    required this.pendingServices,
  });

  final int totalOrders;
  final int completedOrders;
  final double revenue;
  final double commission;
  final double averageRating;
  final int pendingTechnicians;
  final int pendingServices;
}
