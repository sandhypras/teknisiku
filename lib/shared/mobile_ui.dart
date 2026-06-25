import 'package:flutter/material.dart';

import '../app/theme.dart';

IconData categoryIcon(String name) {
  final text = name.toLowerCase();
  if (text.contains('laptop')) return Icons.laptop_mac_rounded;
  if (text.contains('handphone') || text.contains('hp')) {
    return Icons.smartphone_rounded;
  }
  if (text.contains('printer')) return Icons.print_rounded;
  if (text.contains('cctv')) return Icons.videocam_rounded;
  if (text.contains('jaringan')) return Icons.router_rounded;
  return Icons.desktop_windows_rounded;
}

String formatRupiah(double amount) {
  if (amount <= 0) return 'Rp 0';
  return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
}

String orderStatusLabel(String status) => switch (status) {
  'waiting_confirmation' => 'Menunggu teknisi',
  'accepted' => 'Diterima',
  'on_the_way' => 'Teknisi menuju lokasi',
  'inspection' => 'Inspeksi',
  'waiting_price_approval' => 'Setujui biaya',
  'in_progress' => 'Dikerjakan',
  'waiting_payment' => 'Menunggu pembayaran',
  'completed' => 'Selesai',
  'rejected' => 'Ditolak',
  'price_rejected' => 'Biaya ditolak',
  _ => status,
};

Color orderStatusColor(String status) => switch (status) {
  'completed' => AppColors.success,
  'rejected' || 'price_rejected' => AppColors.danger,
  'waiting_confirmation' || 'waiting_price_approval' => AppColors.warning,
  _ => AppColors.secondary,
};

class MobileSectionHeader extends StatelessWidget {
  const MobileSectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final action = this.action;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.secondary, size: 34),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset('assets/logos/logoku.png', fit: BoxFit.contain),
    );
  }
}
