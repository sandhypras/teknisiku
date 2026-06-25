class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalCustomers,
    required this.totalTechnicians,
    required this.pendingTechnicians,
    required this.inactiveAccounts,
    required this.totalServices,
    required this.pendingServices,
    required this.totalOrders,
    required this.activeOrders,
    required this.waitingPayments,
    required this.totalTransaction,
    required this.averageRating,
    required this.recentOrders,
    required this.pendingTechnicianIds,
    required this.pendingServiceNames,
  });

  final int totalCustomers;
  final int totalTechnicians;
  final int pendingTechnicians;
  final int inactiveAccounts;
  final int totalServices;
  final int pendingServices;
  final int totalOrders;
  final int activeOrders;
  final int waitingPayments;
  final double totalTransaction;
  final double averageRating;
  final List<AdminRecentOrder> recentOrders;
  final List<String> pendingTechnicianIds;
  final List<String> pendingServiceNames;
}

class AdminRecentOrder {
  const AdminRecentOrder({
    required this.orderNumber,
    required this.status,
    required this.finalTotal,
    required this.createdAt,
  });

  final String orderNumber;
  final String status;
  final double finalTotal;
  final DateTime? createdAt;

  factory AdminRecentOrder.fromJson(Map<String, dynamic> json) {
    return AdminRecentOrder(
      orderNumber: json['order_number'] as String? ?? '-',
      status: json['status'] as String? ?? '-',
      finalTotal: _asDouble(json['final_total']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  static double _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
