import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../admin_shell.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  // ikon per kategori
  static const _categoryIcons = <String, IconData>{
    'Komputer': Icons.computer_outlined,
    'Laptop': Icons.laptop_outlined,
    'Handphone': Icons.smartphone_outlined,
    'Printer': Icons.print_outlined,
    'CCTV': Icons.videocam_outlined,
    'Jaringan': Icons.wifi_outlined,
  };

  // warna aksen per kategori (variasi shade biru)
  static const _categoryColors = <String, Color>{
    'Komputer': Color(0xFF0D72BD),
    'Laptop': Color(0xFF2283C6),
    'Handphone': Color(0xFF3A97D3),
    'Printer': Color(0xFF0A4F86),
    'CCTV': Color(0xFF1678B9),
    'Jaringan': Color(0xFF2B8CCB),
  };

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await Supabase.instance.client
        .from('categories')
        .select('id, name, description, icon_url, is_active, created_at')
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _toggleActive(String id, bool current) async {
    await Supabase.instance.client
        .from('categories')
        .update({'is_active': !current})
        .eq('id', id);
    setState(() {
      _future = _fetch();
    });
  }

  String? _categoryImageUrl(String? path) {
    return _categoryPublicUrl(path);
  }

  Future<String> _uploadCategoryImage(XFile file) async {
    final extension = _extensionFor(file.name, file.mimeType);
    final path =
        'categories/${DateTime.now().millisecondsSinceEpoch}$extension';
    await Supabase.instance.client.storage
        .from('category-images')
        .uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(
            contentType: file.mimeType ?? _contentTypeFor(extension),
            upsert: true,
          ),
        );
    return 'category-images/$path';
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(
      text: existing?['name'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description'] as String? ?? '',
    );
    bool isActive = existing?['is_active'] as bool? ?? true;
    String? iconUrl = existing?['icon_url'] as String?;
    bool uploading = false;
    bool nameTouched = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final nameError = nameTouched && nameCtrl.text.trim().isEmpty;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Dialog header ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 18, 20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isEdit
                                ? Icons.edit_outlined
                                : Icons.category_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Perbarui detail kategori layanan'
                                    : 'Buat kategori layanan baru',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Icon preview / upload ──
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 92,
                                    height: 92,
                                    decoration: BoxDecoration(
                                      color: AppColors.iconBg,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color:
                                            _categoryImageUrl(iconUrl) == null
                                            ? AppColors.border
                                            : AppColors.primaryBlue.withValues(
                                                alpha: 0.25,
                                              ),
                                        width: 1.4,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: uploading
                                        ? const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          )
                                        : _categoryImageUrl(iconUrl) == null
                                        ? const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: AppColors.primaryBlue,
                                            size: 30,
                                          )
                                        : Image.network(
                                            _categoryImageUrl(iconUrl)!,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.broken_image_outlined,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                  ),
                                  if (iconUrl != null && !uploading)
                                    Positioned(
                                      right: -6,
                                      top: -6,
                                      child: InkWell(
                                        onTap: () => setS(() => iconUrl = null),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextButton.icon(
                                onPressed: uploading
                                    ? null
                                    : () async {
                                        final file = await ImagePicker()
                                            .pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 86,
                                              maxWidth: 1200,
                                            );
                                        if (file == null) return;
                                        setS(() => uploading = true);
                                        try {
                                          final uploaded =
                                              await _uploadCategoryImage(file);
                                          setS(() => iconUrl = uploaded);
                                          if (existing != null) {
                                            await Supabase.instance.client
                                                .from('categories')
                                                .update({'icon_url': uploaded})
                                                .eq(
                                                  'id',
                                                  existing['id'] as String,
                                                );
                                            if (mounted) {
                                              setState(() {
                                                _future = _fetch();
                                              });
                                            }
                                          }
                                        } finally {
                                          setS(() => uploading = false);
                                        }
                                      },
                                icon: Icon(
                                  iconUrl == null
                                      ? Icons.upload_rounded
                                      : Icons.swap_horiz_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  uploading
                                      ? 'Mengupload...'
                                      : iconUrl == null
                                      ? 'Pilih icon kategori'
                                      : 'Ganti icon',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── Nama ──
                        _InputField(
                          controller: nameCtrl,
                          label: 'Nama Kategori',
                          hint: 'Contoh: Komputer',
                          icon: Icons.label_outline,
                          errorText: nameError
                              ? 'Nama kategori wajib diisi'
                              : null,
                          onChanged: (_) {
                            if (!nameTouched) setS(() => nameTouched = true);
                            setS(() {});
                          },
                        ),
                        const SizedBox(height: 14),

                        // ── Deskripsi ──
                        _InputField(
                          controller: descCtrl,
                          label: 'Deskripsi',
                          hint: 'Deskripsi singkat kategori (opsional)',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // ── Status switch ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.06)
                                : AppColors.bgPage,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.25)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.pause_circle_outline_rounded,
                                size: 20,
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isActive
                                          ? 'Kategori aktif'
                                          : 'Kategori nonaktif',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isActive
                                            ? AppColors.darkBlue
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      isActive
                                          ? 'Tampil di daftar layanan customer'
                                          : 'Tersembunyi dari customer',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isActive,
                                activeThumbColor: AppColors.primaryBlue,
                                activeTrackColor: AppColors.softBlue,
                                onChanged: (v) => setS(() => isActive = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Actions ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.heroGradient,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: 0.30,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  setS(() => nameTouched = true);
                                  return;
                                }
                                Navigator.pop(ctx);
                                if (existing == null) {
                                  await Supabase.instance.client
                                      .from('categories')
                                      .insert({
                                        'name': name,
                                        'description':
                                            descCtrl.text.trim().isEmpty
                                            ? null
                                            : descCtrl.text.trim(),
                                        'icon_url': iconUrl,
                                        'is_active': isActive,
                                      });
                                } else {
                                  await Supabase.instance.client
                                      .from('categories')
                                      .update({
                                        'name': name,
                                        'description':
                                            descCtrl.text.trim().isEmpty
                                            ? null
                                            : descCtrl.text.trim(),
                                        'icon_url': iconUrl,
                                        'is_active': isActive,
                                      })
                                      .eq('id', existing['id'] as String);
                                }
                                setState(() {
                                  _future = _fetch();
                                });
                              },
                              icon: Icon(
                                isEdit
                                    ? Icons.save_outlined
                                    : Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                isEdit ? 'Update Kategori' : 'Simpan Kategori',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 32,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Hapus Kategori?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgPage,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tindakan ini tidak dapat dibatalkan. Layanan yang masih terkait dengan kategori ini tidak dapat dihapus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Supabase.instance.client
                              .from('categories')
                              .delete()
                              .eq('id', id);
                          setState(() {
                            _future = _fetch();
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                        ),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
            color: AppColors.bgPage,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategori',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kelola kategori layanan Si Teknisi',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _OutlineButton(
                  icon: Icons.refresh_outlined,
                  label: 'Refresh',
                  onPressed: () => setState(() {
                    _future = _fetch();
                  }),
                ),
                const SizedBox(width: 10),
                _GradientButton(
                  icon: Icons.add_rounded,
                  label: 'Tambah Kategori',
                  onPressed: _showAddEditDialog,
                ),
              ],
            ),
          ),

          // ── Stats bar ──
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (_, snap) {
              if (snap.data == null) return const SizedBox.shrink();
              final all = snap.data!;
              final active = all.where((c) => c['is_active'] == true).length;
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                child: Row(
                  children: [
                    _MiniStatChip(
                      label: 'Total',
                      value: '${all.length}',
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatChip(
                      label: 'Aktif',
                      value: '$active',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _MiniStatChip(
                      label: 'Nonaktif',
                      value: '${all.length - active}',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Grid ──
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GradientButton(
                          icon: Icons.refresh_outlined,
                          label: 'Coba lagi',
                          onPressed: () => setState(() {
                            _future = _fetch();
                          }),
                        ),
                      ],
                    ),
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const AdminEmptyState(message: 'Belum ada kategori');
                }
                return LayoutBuilder(
                  builder: (_, constraints) {
                    final cols = constraints.maxWidth > 1100
                        ? 3
                        : constraints.maxWidth > 700
                        ? 2
                        : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.6,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _CategoryCard(
                        data: list[i],
                        icon:
                            _categoryIcons[list[i]['name']] ??
                            Icons.miscellaneous_services_outlined,
                        accentColor:
                            _categoryColors[list[i]['name']] ??
                            AppColors.primaryBlue,
                        onEdit: () => _showAddEditDialog(existing: list[i]),
                        onToggle: () => _toggleActive(
                          list[i]['id'] as String,
                          list[i]['is_active'] as bool? ?? true,
                        ),
                        onDelete: () => _confirmDelete(
                          list[i]['id'] as String,
                          list[i]['name'] as String,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Card ─────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.data,
    required this.icon,
    required this.accentColor,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final Map<String, dynamic> data;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.data['is_active'] as bool? ?? true;
    final name = widget.data['name'] as String? ?? '-';
    final desc = widget.data['description'] as String? ?? '';
    final imageUrl = _categoryPublicUrl(widget.data['icon_url'] as String?);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? widget.accentColor.withValues(alpha: 0.4)
                : AppColors.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.accentColor.withValues(alpha: 0.12)
                  : const Color(0x080A4F86),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // ── Ikon ──
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.2),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl == null
                    ? Icon(widget.icon, color: widget.accentColor, size: 26)
                    : Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              Icon(widget.icon, color: widget.accentColor),
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? AppColors.darkBlue
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        // status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.textSecondary.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Aksi ──
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                    tooltip: 'Edit',
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(height: 4),
                  _IconBtn(
                    icon: isActive
                        ? Icons.toggle_on_outlined
                        : Icons.toggle_off_outlined,
                    color: isActive
                        ? AppColors.success
                        : AppColors.textSecondary,
                    tooltip: isActive ? 'Nonaktifkan' : 'Aktifkan',
                    onTap: widget.onToggle,
                  ),
                  const SizedBox(height: 4),
                  _IconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    tooltip: 'Hapus',
                    onTap: widget.onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ──────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryBlue),
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.bgPage,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.check_outlined, size: 16, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon ?? Icons.refresh_outlined,
        size: 16,
        color: AppColors.primaryBlue,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String? _categoryPublicUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final value = path.trim();
  if (value.startsWith('http')) return value;

  const supportedBuckets = [
    'category-images',
    'service-images',
    'profile-images',
  ];
  var bucket = 'category-images';
  var objectPath = value;
  for (final candidate in supportedBuckets) {
    final prefix = '$candidate/';
    if (value.startsWith(prefix)) {
      bucket = candidate;
      objectPath = value.substring(prefix.length);
      break;
    }
  }
  if (objectPath.isEmpty) return null;

  return Supabase.instance.client.storage.from(bucket).getPublicUrl(objectPath);
}

String _extensionFor(String fileName, String? mimeType) {
  final lower = fileName.toLowerCase();
  final dot = lower.lastIndexOf('.');
  if (dot >= 0 && dot < lower.length - 1) {
    final extension = lower.substring(dot);
    if (['.jpg', '.jpeg', '.png', '.webp'].contains(extension)) {
      return extension;
    }
  }
  return switch (mimeType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    _ => '.jpg',
  };
}

String _contentTypeFor(String extension) {
  return switch (extension) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
