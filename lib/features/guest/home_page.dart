import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../auth/login_page.dart';

class GuestHomePage extends StatelessWidget {
  const GuestHomePage({super.key});

  static const _categories = [
    _ServiceCategory('Komputer', Icons.desktop_windows_outlined),
    _ServiceCategory('Laptop', Icons.laptop_mac_outlined),
    _ServiceCategory('Handphone', Icons.smartphone_outlined),
    _ServiceCategory('Printer', Icons.print_outlined),
    _ServiceCategory('CCTV', Icons.videocam_outlined),
    _ServiceCategory('Jaringan', Icons.router_outlined),
  ];

  static const _technicians = [
    _Technician('Budi Santoso', 'Laptop dan komputer', 'Solo Kota', 4.8),
    _Technician('Rina Pratama', 'Printer dan jaringan', 'Laweyan', 4.7),
    _Technician('Agus Wijaya', 'CCTV dan instalasi', 'Jebres', 4.9),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Si Teknisi'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            child: const Text('Masuk'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HeroSection(),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Kategori layanan',
              actionLabel: 'Lihat semua',
              onActionPressed: () {},
            ),
            const SizedBox(height: 12),
            const _CategoryGrid(categories: _categories),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Teknisi unggulan',
              actionLabel: 'Cari teknisi',
              onActionPressed: () {},
            ),
            const SizedBox(height: 12),
            for (final technician in _technicians) ...[
              _TechnicianCard(technician: technician),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temukan teknisi terpercaya di Solo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih layanan, cek estimasi harga, lalu pesan teknisi sesuai kebutuhan.',
            style: TextStyle(color: Color(0xFFE5E7EB), height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.search),
            label: const Text('Cari layanan'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TextButton(onPressed: onActionPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<_ServiceCategory> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category.icon, color: AppColors.secondary, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({required this.technician});

  final _Technician technician;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                foregroundColor: AppColors.secondary,
                child: const Icon(Icons.engineering_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technician.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${technician.skill} - ${technician.area}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.warning, size: 18),
                  const SizedBox(width: 4),
                  Text(technician.rating.toStringAsFixed(1)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCategory {
  const _ServiceCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

class _Technician {
  const _Technician(this.name, this.skill, this.area, this.rating);

  final String name;
  final String skill;
  final String area;
  final double rating;
}
