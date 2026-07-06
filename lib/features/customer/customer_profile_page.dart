import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../../shared/widgets/app_feedback.dart';
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

  Future<void> _confirmSignOut() async {
    if (!await AppFeedback.confirmLogout(context)) return;
    await widget.authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F8FF), Color(0xFFFAFCFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.30],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_CustomerProfileData>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 28),
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
                          onSignOut: _confirmSignOut,
                        ),
                        const SizedBox(height: 16),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else if (snapshot.hasError)
                          ErrorState(
                            message: snapshot.error.toString(),
                            onRetry: _refresh,
                          )
                        else ...[
                          _AddressSection(addresses: data?.addresses ?? []),
                          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(20),
      decoration: _profileCardDecoration(),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.55),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
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
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profile.fullName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            profile.email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if ((profile.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              profile.phone!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          StatusPill(label: profile.role.label, color: AppColors.primary),
          const SizedBox(height: 22),
          const Divider(height: 1, color: Color(0xFFEEF3FA)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: Color(0xFFF3D6D6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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
          ? const _SectionEmpty(
              icon: Icons.location_off_outlined,
              message: 'Belum ada alamat tersimpan.',
            )
          : Column(
              children: [
                for (var i = 0; i < addresses.length; i++) ...[
                  _AddressRow(address: addresses[i]),
                  if (i != addresses.length - 1)
                    const Divider(height: 1, color: Color(0xFFEEF3FA)),
                ],
              ],
            ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address});

  final CustomerAddress address;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              address.isPrimary
                  ? Icons.home_rounded
                  : Icons.location_city_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (address.isPrimary)
                      const StatusPill(
                        label: 'Utama',
                        color: AppColors.success,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${address.fullAddress}, ${address.city}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          ? const _SectionEmpty(
              icon: Icons.inbox_outlined,
              message: 'Belum ada pesanan.',
            )
          : Column(
              children: [
                for (var i = 0; i < orders.take(4).length; i++) ...[
                  _OrderRow(order: orders[i]),
                  if (i != orders.take(4).length - 1)
                    const Divider(height: 1, color: Color(0xFFEEF3FA)),
                ],
              ],
            ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: orderStatusColor(order.status).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: orderStatusColor(order.status),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  orderStatusLabel(order.status),
                  style: TextStyle(
                    color: orderStatusColor(order.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(total),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
