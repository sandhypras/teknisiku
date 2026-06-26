import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_shell.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await Supabase.instance.client
        .from('reviews')
        .select(
          'id, rating, comment, image_url, created_at, order:orders!order_id(order_number), customer:profiles!customer_id(full_name), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _delete(String id) async {
    await Supabase.instance.client.from('reviews').delete().eq('id', id);
    setState(() {
      _future = _fetch();
    });
  }

  Future<void> _updateReview(
    String id, {
    required int rating,
    required String comment,
  }) async {
    await Supabase.instance.client
        .from('reviews')
        .update({
          'rating': rating,
          'comment': comment.trim().isEmpty ? null : comment.trim(),
        })
        .eq('id', id);
    setState(() {
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            title: 'Ulasan',
            subtitle: 'Pantau feedback customer',
            onRefresh: () => setState(() {
              _future = _fetch();
            }),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return AdminErrorState(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _future = _fetch();
                    }),
                  );
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const AdminEmptyState(message: 'Belum ada ulasan');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: rows.length,
                  itemBuilder: (_, i) => _ReviewCard(
                    data: rows[i],
                    onDetail: () => _showReviewDetail(rows[i]),
                    onEdit: () => _showReviewEdit(rows[i]),
                    onDelete: () => _delete(rows[i]['id'] as String),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDetail(Map<String, dynamic> data) {
    final customer = data['customer'] as Map<String, dynamic>?;
    final technician =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    final order = data['order'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Detail Ulasan'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine('Customer', '${customer?['full_name'] ?? '-'}'),
              _DetailLine('Teknisi', '${technician?['full_name'] ?? '-'}'),
              _DetailLine('Order', '${order?['order_number'] ?? '-'}'),
              _DetailLine('Rating', '${data['rating'] ?? 0}/5'),
              const Divider(height: 24),
              Text(data['comment'] as String? ?? 'Tidak ada komentar'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showReviewEdit(Map<String, dynamic> data) {
    var rating = (data['rating'] as num?)?.toInt() ?? 5;
    final commentCtrl = TextEditingController(
      text: data['comment'] as String? ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Edit Ulasan'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: rating.clamp(1, 5),
                  decoration: const InputDecoration(labelText: 'Rating'),
                  items: List.generate(
                    5,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} bintang'),
                    ),
                  ),
                  onChanged: (value) => setS(() => rating = value ?? rating),
                ),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(labelText: 'Komentar'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReview(
                  data['id'] as String,
                  rating: rating,
                  comment: commentCtrl.text,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.data,
    required this.onDelete,
    required this.onDetail,
    required this.onEdit,
  });
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final VoidCallback onDetail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final customer = data['customer'] as Map<String, dynamic>?;
    final technician =
        (data['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    final order = data['order'] as Map<String, dynamic>?;
    final rating = (data['rating'] as num?)?.toInt() ?? 0;

    return AdminDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.iconBg,
                child: Text(
                  (customer?['full_name'] as String? ?? 'C')[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?['full_name'] as String? ?? '-',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${order?['order_number'] ?? '-'} -> ${technician?['full_name'] ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDetail,
                tooltip: 'Detail ulasan',
                icon: const Icon(Icons.visibility_outlined),
                color: AppColors.primaryBlue,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
          ),
          if ((data['comment'] as String?)?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              data['comment'] as String,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
