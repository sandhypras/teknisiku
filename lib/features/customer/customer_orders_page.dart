import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'customer_shell_page.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  late Future<List<OrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repo.customerOrders();
  }

  void _refresh() => setState(() => _future = widget.repo.customerOrders());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const CustomerAppBar(
            title: 'Pesanan Saya',
            subtitle: 'Status order tersinkron dengan Supabase',
          ),
          Expanded(
            child: FutureBuilder<List<OrderSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return const EmptyState(message: 'Belum ada pesanan');
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: orders.length,
                    itemBuilder: (_, index) => _OrderCard(order: orders[index]),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(label: orderStatusLabel(order.status), color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Teknisi: ${order.technicianName}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Jadwal: ${order.scheduleDate} ${order.scheduleTime}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (order.finalTotal > 0 || order.estimatedTotal > 0) ...[
            const Divider(height: 22),
            Text(
              'Total: ${formatRupiah(order.finalTotal > 0 ? order.finalTotal : order.estimatedTotal)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
