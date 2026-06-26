import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import 'customer_shell_page.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({
    required this.profile,
    required this.authService,
    super.key,
  });

  final AppProfile profile;
  final AuthService authService;

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  late final MarketplaceRepository _repo;
  late Future<_CustomerProfileData> _future;

  @override
  void initState() {
    super.initState();
    _repo = MarketplaceRepository(Supabase.instance.client);
    _future = _load();
  }

  Future<_CustomerProfileData> _load() async {
    final results = await Future.wait([
      _repo.customerAddresses(),
      _repo.customerOrders(),
    ]);
    return _CustomerProfileData(
      addresses: results[0] as List<CustomerAddress>,
      orders: results[1] as List<OrderSummary>,
    );
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<_CustomerProfileData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const CustomerAppBar(
                  title: 'Profil',
                  subtitle: 'Data akun, alamat, dan riwayat pesanan',
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _ProfileCard(
                        profile: widget.profile,
                        onSignOut: widget.authService.signOut,
                      ),
                      const SizedBox(height: 14),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError)
                        ErrorState(
                          message: snapshot.error.toString(),
                          onRetry: _refresh,
                        )
                      else ...[
                        _AddressSection(addresses: data?.addresses ?? []),
                        const SizedBox(height: 14),
                        _RecentOrderSection(orders: data?.orders ?? []),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onSignOut});

  final AppProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _profileCardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
            child: Text(
              profile.fullName.isEmpty
                  ? 'C'
                  : profile.fullName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            profile.email,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if ((profile.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              profile.phone!,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          StatusPill(label: profile.role.label, color: AppColors.primary),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.addresses});

  final List<CustomerAddress> addresses;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Alamat Tersimpan',
      icon: Icons.location_on_outlined,
      child: addresses.isEmpty
          ? const Text(
              'Belum ada alamat tersimpan.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: addresses
                  .map(
                    (address) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        address.isPrimary
                            ? Icons.home_rounded
                            : Icons.location_city_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        address.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text('${address.fullAddress}, ${address.city}'),
                      trailing: address.isPrimary
                          ? const StatusPill(
                              label: 'Utama',
                              color: AppColors.success,
                            )
                          : null,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _RecentOrderSection extends StatelessWidget {
  const _RecentOrderSection({required this.orders});

  final List<OrderSummary> orders;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Pesanan Terakhir',
      icon: Icons.receipt_long_outlined,
      child: orders.isEmpty
          ? const Text(
              'Belum ada pesanan.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: orders.take(4).map((order) {
                final total = order.finalTotal > 0
                    ? order.finalTotal
                    : order.estimatedTotal;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(orderStatusLabel(order.status)),
                  trailing: Text(
                    formatRupiah(total),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CustomerProfileData {
  const _CustomerProfileData({required this.addresses, required this.orders});

  final List<CustomerAddress> addresses;
  final List<OrderSummary> orders;
}

BoxDecoration _profileCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE3ECF6)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.07),
        blurRadius: 14,
        offset: const Offset(0, 7),
      ),
    ],
  );
}
