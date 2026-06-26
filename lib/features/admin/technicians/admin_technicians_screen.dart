import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_shell.dart';

class AdminTechniciansScreen extends StatefulWidget {
  const AdminTechniciansScreen({super.key});

  @override
  State<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends State<AdminTechniciansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _future;

  final _tabs = const ['Semua', 'Pending', 'Verified', 'Rejected'];
  final _filters = [null, 'pending', 'verified', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(
      () => setState(() {
        _future = _fetch(_filters[_tabController.index]);
      }),
    );
    _future = _fetch(null);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch(String? status) async {
    final q = Supabase.instance.client
        .from('technician_profiles')
        .select(
          'id, verification_status, verified_at, rejection_reason, skills, service_area, created_at, profile:profiles!user_id(full_name, email, phone), documents:technician_documents(id, document_type, file_url, uploaded_at)',
        );
    final data = status != null
        ? await q
              .eq('verification_status', status)
              .order('created_at', ascending: false)
        : await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _updateStatus(String id, String status, {String? reason}) async {
    await Supabase.instance.client
        .from('technician_profiles')
        .update({
          'verification_status': status,
          if (status == 'verified')
            'verified_at': DateTime.now().toIso8601String(),
          'rejection_reason': ?reason,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch(_filters[_tabController.index]);
    });
  }

  Future<void> _updateTechnician(
    String id, {
    required String serviceArea,
    required String skills,
    required String status,
  }) async {
    await Supabase.instance.client
        .from('technician_profiles')
        .update({
          'service_area': serviceArea.trim().isEmpty
              ? 'Solo'
              : serviceArea.trim(),
          'skills': skills
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(),
          'verification_status': status,
        })
        .eq('id', id);
    setState(() {
      _future = _fetch(_filters[_tabController.index]);
    });
  }

  Future<void> _deleteTechnician(String id) async {
    await Supabase.instance.client
        .from('technician_profiles')
        .delete()
        .eq('id', id);
    setState(() {
      _future = _fetch(_filters[_tabController.index]);
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
            title: 'Teknisi',
            subtitle: 'Kelola dan verifikasi teknisi',
            onRefresh: () => setState(
              () => _future = _fetch(_filters[_tabController.index]),
            ),
          ),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const AdminEmptyState(message: 'Tidak ada teknisi');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _TechnicianCard(
                    data: list[i],
                    onVerify: () =>
                        _updateStatus(list[i]['id'] as String, 'verified'),
                    onReject: () =>
                        _showRejectDialog(context, list[i]['id'] as String),
                    onDeactivate: () =>
                        _updateStatus(list[i]['id'] as String, 'inactive'),
                    onViewDocument: _showDocumentPreview,
                    onDetail: () => _showTechnicianDetail(list[i]),
                    onEdit: () => _showTechnicianEdit(list[i]),
                    onDelete: () => _confirmDeleteTechnician(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String id) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tolak Teknisi'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, 'rejected', reason: ctrl.text);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDocumentPreview(Map<String, dynamic> document) async {
    final fileUrl = document['file_url'] as String? ?? '';
    final title = switch (document['document_type'] as String? ?? '') {
      'ktp' => 'Foto KTP',
      'selfie' => 'Foto Selfie',
      _ => 'Dokumen Teknisi',
    };
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          height: 420,
          child: FutureBuilder<String>(
            future: _signedDocumentUrl(fileUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  snapshot.data!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Text('Gagal memuat gambar dokumen')),
                ),
              );
            },
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

  Future<String> _signedDocumentUrl(String fileUrl) async {
    if (fileUrl.startsWith('http')) return fileUrl;
    final path = fileUrl.replaceFirst('technician-documents/', '');
    return Supabase.instance.client.storage
        .from('technician-documents')
        .createSignedUrl(path, 60 * 10);
  }

  void _showTechnicianDetail(Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>?;
    final skills = (data['skills'] as List?)?.join(', ') ?? '-';
    final docs = List<Map<String, dynamic>>.from(
      data['documents'] as List? ?? const [],
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(profile?['full_name'] as String? ?? 'Detail Teknisi'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailLine('Email', profile?['email'] as String? ?? '-'),
              _DetailLine('Telepon', profile?['phone'] as String? ?? '-'),
              _DetailLine('Area', data['service_area'] as String? ?? '-'),
              _DetailLine('Keahlian', skills),
              _DetailLine(
                'Status',
                data['verification_status'] as String? ?? '-',
              ),
              const Divider(height: 24),
              const Text(
                'Dokumen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: docs
                    .map(
                      (doc) => ActionChip(
                        avatar: const Icon(Icons.visibility_rounded, size: 16),
                        label: Text(
                          doc['document_type'] as String? ?? 'dokumen',
                        ),
                        onPressed: () => _showDocumentPreview(doc),
                      ),
                    )
                    .toList(),
              ),
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

  void _showTechnicianEdit(Map<String, dynamic> data) {
    final areaCtrl = TextEditingController(
      text: data['service_area'] as String? ?? 'Solo',
    );
    final skillsCtrl = TextEditingController(
      text: (data['skills'] as List?)?.join(', ') ?? '',
    );
    var status = data['verification_status'] as String? ?? 'pending';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: const Text('Edit Teknisi'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: areaCtrl,
                  decoration: const InputDecoration(labelText: 'Area layanan'),
                ),
                TextField(
                  controller: skillsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Keahlian, pisahkan koma',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Status verifikasi',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'verified',
                      child: Text('Verified'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) => setS(() => status = value ?? status),
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
                _updateTechnician(
                  data['id'] as String,
                  serviceArea: areaCtrl.text,
                  skills: skillsCtrl.text,
                  status: status,
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTechnician(Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>?;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Teknisi'),
        content: Text('Hapus profil teknisi ${profile?['full_name'] ?? ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTechnician(data['id'] as String);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.data,
    required this.onVerify,
    required this.onReject,
    required this.onDeactivate,
    required this.onViewDocument,
    required this.onDetail,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onDeactivate;
  final ValueChanged<Map<String, dynamic>> onViewDocument;
  final VoidCallback onDetail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final profile = data['profile'] as Map<String, dynamic>?;
    final status = data['verification_status'] as String? ?? '';
    final badge = _badge(status);
    final skills = (data['skills'] as List?)?.cast<String>() ?? [];
    final documents = List<Map<String, dynamic>>.from(
      data['documents'] as List? ?? const [],
    );
    final ktp = _documentByType(documents, 'ktp');
    final selfie = _documentByType(documents, 'selfie');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                  child: Text(
                    (profile?['full_name'] as String? ?? 'T')[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?['full_name'] as String? ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        profile?['email'] as String? ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  label: badge.label,
                  color: badge.color,
                  bg: badge.bg,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'detail') onDetail();
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'detail', child: Text('Detail')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: skills
                    .take(4)
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DocumentChip(
                  label: 'KTP',
                  document: ktp,
                  onTap: ktp == null ? null : () => onViewDocument(ktp),
                ),
                _DocumentChip(
                  label: 'Selfie',
                  document: selfie,
                  onTap: selfie == null ? null : () => onViewDocument(selfie),
                ),
              ],
            ),
            if ((data['rejection_reason'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['rejection_reason'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onVerify,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Verifikasi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'verified') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onDeactivate,
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Nonaktifkan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _BadgeStyle _badge(String status) => switch (status) {
    'pending' => _BadgeStyle(
      'Pending',
      AppColors.warning,
      AppColors.warning.withValues(alpha: 0.12),
    ),
    'verified' => _BadgeStyle(
      'Verified',
      AppColors.success,
      AppColors.success.withValues(alpha: 0.12),
    ),
    'rejected' => _BadgeStyle(
      'Rejected',
      AppColors.error,
      AppColors.error.withValues(alpha: 0.12),
    ),
    'inactive' => _BadgeStyle(
      'Inactive',
      AppColors.textSecondary,
      AppColors.textSecondary.withValues(alpha: 0.12),
    ),
    _ => _BadgeStyle(
      'Unknown',
      AppColors.textSecondary,
      AppColors.textSecondary.withValues(alpha: 0.1),
    ),
  };
}

Map<String, dynamic>? _documentByType(
  List<Map<String, dynamic>> documents,
  String type,
) {
  for (final document in documents) {
    if (document['document_type'] == type) return document;
  }
  return null;
}

class _DocumentChip extends StatelessWidget {
  const _DocumentChip({
    required this.label,
    required this.document,
    required this.onTap,
  });

  final String label;
  final Map<String, dynamic>? document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final uploaded = document != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: uploaded
              ? AppColors.success.withValues(alpha: 0.10)
              : AppColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: uploaded
                ? AppColors.success.withValues(alpha: 0.28)
                : AppColors.warning.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              uploaded
                  ? Icons.visibility_rounded
                  : Icons.hourglass_empty_rounded,
              color: uploaded ? AppColors.success : AppColors.warning,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              uploaded ? 'Lihat $label' : '$label belum upload',
              style: TextStyle(
                color: uploaded ? AppColors.success : AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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

class _BadgeStyle {
  const _BadgeStyle(this.label, this.color, this.bg);
  final String label;
  final Color color;
  final Color bg;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
  });
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
