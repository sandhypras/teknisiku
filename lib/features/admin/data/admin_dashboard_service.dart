import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_dashboard_summary.dart';

class AdminDashboardService {
  AdminDashboardService(this._supabase);

  final SupabaseClient _supabase;

  Future<AdminDashboardSummary> loadSummary() async {
    final profiles = await _supabase
        .from('profiles')
        .select('id, role, is_active, created_at')
        .order('created_at', ascending: false);
    final technicians = await _supabase
        .from('technician_profiles')
        .select('id, user_id, verification_status, created_at')
        .order('created_at', ascending: false);
    final services = await _supabase
        .from('services')
        .select('id, name, approval_status, is_active, created_at')
        .order('created_at', ascending: false);
    final orders = await _supabase
        .from('orders')
        .select('id, order_number, status, final_total, created_at')
        .order('created_at', ascending: false);
    final payments = await _supabase
        .from('payments')
        .select('id, amount, payment_status, created_at')
        .order('created_at', ascending: false);
    final reviews = await _supabase.from('reviews').select('id, rating');

    final profileRows = _rows(profiles);
    final technicianRows = _rows(technicians);
    final serviceRows = _rows(services);
    final orderRows = _rows(orders);
    final paymentRows = _rows(payments);
    final reviewRows = _rows(reviews);

    final paidPayments = paymentRows.where(
      (row) => row['payment_status'] == 'paid',
    );
    final totalTransaction = paidPayments.fold<double>(
      0,
      (total, row) => total + _asDouble(row['amount']),
    );

    final ratings = reviewRows
        .map((row) => _asDouble(row['rating']))
        .where((rating) => rating > 0)
        .toList();

    return AdminDashboardSummary(
      totalCustomers: profileRows
          .where((row) => row['role'] == 'customer')
          .length,
      totalTechnicians: technicianRows.length,
      pendingTechnicians: technicianRows
          .where((row) => row['verification_status'] == 'pending')
          .length,
      inactiveAccounts: profileRows
          .where((row) => row['is_active'] == false)
          .length,
      totalServices: serviceRows.length,
      pendingServices: serviceRows
          .where((row) => row['approval_status'] == 'pending')
          .length,
      totalOrders: orderRows.length,
      activeOrders: orderRows
          .where(
            (row) => !{
              'completed',
              'rejected',
              'price_rejected',
            }.contains(row['status']),
          )
          .length,
      waitingPayments: paymentRows
          .where((row) => row['payment_status'] == 'waiting_verification')
          .length,
      totalTransaction: totalTransaction,
      averageRating: ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length,
      recentOrders: orderRows.take(6).map(AdminRecentOrder.fromJson).toList(),
      pendingTechnicianIds: technicianRows
          .where((row) => row['verification_status'] == 'pending')
          .take(5)
          .map((row) => row['id'] as String)
          .toList(),
      pendingServiceNames: serviceRows
          .where((row) => row['approval_status'] == 'pending')
          .take(5)
          .map((row) => row['name'] as String? ?? 'Layanan tanpa nama')
          .toList(),
    );
  }

  List<Map<String, dynamic>> _rows(Object response) {
    return (response as List)
        .cast<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
