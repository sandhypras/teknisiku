import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_shell.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _searchCtrl = TextEditingController();
  String _search = '';
  List<Map<String, dynamic>> _allCustomers = [];

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    _searchCtrl.addListener(() {
      if (_search != _searchCtrl.text) {
        setState(() => _search = _searchCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, email, phone, is_active, created_at')
        .eq('role', 'customer')
        .order('created_at', ascending: false)
        .limit(100);
    _allCustomers = List<Map<String, dynamic>>.from(data);
    return _allCustomers;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _allCustomers;
    final q = _search.trim().toLowerCase();
    return _allCustomers
        .where((c) =>
            (c['full_name'] as String? ?? '').toLowerCase().contains(q) ||
            (c['email'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  Future<void> _toggleActive(String userId, bool currentActive) async {
    await Supabase.instance.client
        .from('profiles')
        .update({'is_active': !currentActive})
        .eq('id', userId);
    setState(() => _future = _fetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Customer',
            subtitle: 'Kelola data customer',
            onRefresh: () => setState(() => _future = _fetch()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = _filtered;
                if (list.isEmpty) {
                  return const AdminEmptyState(message: 'Tidak ada customer');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _CustomerCard(
                    data: list[i],
                    onToggleActive: () => _toggleActive(
                        list[i]['id'] as String,
                        list[i]['is_active'] as bool? ?? true),
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.data, required this.onToggleActive});
  final Map<String, dynamic> data;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final isActive = data['is_active'] as bool? ?? true;
    final name = data['full_name'] as String? ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isActive
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? AppColors.primary : Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary)),
                  Text(data['email'] as String? ?? '-',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if ((data['phone'] as String?)?.isNotEmpty == true)
                    Text(data['phone'] as String,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        fontSize: 11,
                        color: isActive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onToggleActive,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      size: 18,
                      color: isActive ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
