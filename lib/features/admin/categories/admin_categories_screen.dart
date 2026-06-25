import 'package:flutter/material.dart';
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
    'Komputer':  Icons.computer_outlined,
    'Laptop':    Icons.laptop_outlined,
    'Handphone': Icons.smartphone_outlined,
    'Printer':   Icons.print_outlined,
    'CCTV':      Icons.videocam_outlined,
    'Jaringan':  Icons.wifi_outlined,
  };

  // warna aksen per kategori (variasi shade biru)
  static const _categoryColors = <String, Color>{
    'Komputer':  Color(0xFF0D72BD),
    'Laptop':    Color(0xFF2283C6),
    'Handphone': Color(0xFF3A97D3),
    'Printer':   Color(0xFF0A4F86),
    'CCTV':      Color(0xFF1678B9),
    'Jaringan':  Color(0xFF2B8CCB),
  };

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final data = await Supabase.instance.client
        .from('categories')
        .select('id, name, description, is_active, created_at')
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _toggleActive(String id, bool current) async {
    await Supabase.instance.client
        .from('categories')
        .update({'is_active': !current})
        .eq('id', id);
    setState(() => _future = _fetch());
  }

  void _showAddEditDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(
        text: existing?['name'] as String? ?? '');
    final descCtrl = TextEditingController(
        text: existing?['description'] as String? ?? '');
    bool isActive = existing?['is_active'] as bool? ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.category_outlined,
                    color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                existing == null ? 'Tambah Kategori' : 'Edit Kategori',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue),
              ),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InputField(
                  controller: nameCtrl,
                  label: 'Nama Kategori',
                  hint: 'Contoh: Komputer',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 14),
                _InputField(
                  controller: descCtrl,
                  label: 'Deskripsi',
                  hint: 'Deskripsi singkat kategori',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Switch(
                      value: isActive,
                      activeThumbColor: AppColors.primaryBlue,
                      activeTrackColor: AppColors.softBlue,
                      onChanged: (v) => setS(() => isActive = v),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isActive ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  if (existing == null) {
                    await Supabase.instance.client
                        .from('categories')
                        .insert({
                      'name': name,
                      'description':
                          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      'is_active': isActive,
                    });
                  } else {
                    await Supabase.instance.client
                        .from('categories')
                        .update({
                      'name': name,
                      'description':
                          descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                      'is_active': isActive,
                    }).eq('id', existing['id'] as String);
                  }
                  setState(() => _future = _fetch());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  existing == null ? 'Simpan' : 'Update',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Kategori',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
        content: Text(
          'Yakin ingin menghapus kategori "$name"?\nLayanan yang terkait tidak dapat dihapus.',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Supabase.instance.client
                  .from('categories')
                  .delete()
                  .eq('id', id);
              setState(() => _future = _fetch());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
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
                    const Text('Kategori',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue)),
                    const SizedBox(height: 2),
                    const Text('Kelola kategori layanan Si Teknisi',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary)),
                  ],
                ),
                const Spacer(),
                _OutlineButton(
                  icon: Icons.refresh_outlined,
                  label: 'Refresh',
                  onPressed: () => setState(() => _future = _fetch()),
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
                        label: 'Total', value: '${all.length}',
                        color: AppColors.primaryBlue),
                    const SizedBox(width: 10),
                    _MiniStatChip(
                        label: 'Aktif', value: '$active',
                        color: AppColors.success),
                    const SizedBox(width: 10),
                    _MiniStatChip(
                        label: 'Nonaktif',
                        value: '${all.length - active}',
                        color: AppColors.textSecondary),
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
                        color: AppColors.primaryBlue),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(snapshot.error.toString(),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        const SizedBox(height: 12),
                        _GradientButton(
                          icon: Icons.refresh_outlined,
                          label: 'Coba lagi',
                          onPressed: () =>
                              setState(() => _future = _fetch()),
                        ),
                      ],
                    ),
                  );
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const AdminEmptyState(
                      message: 'Belum ada kategori');
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
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.6,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _CategoryCard(
                        data: list[i],
                        icon: _categoryIcons[list[i]['name']] ??
                            Icons.miscellaneous_services_outlined,
                        accentColor:
                            _categoryColors[list[i]['name']] ??
                                AppColors.primaryBlue,
                        onEdit: () =>
                            _showAddEditDialog(existing: list[i]),
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
                child: Icon(widget.icon,
                    color: widget.accentColor, size: 26),
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
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.1),
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
                            color: AppColors.textSecondary),
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
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryBlue),
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        hintStyle:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        icon: Icon(icon ?? Icons.check_outlined,
            size: 16, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
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
      icon: Icon(icon ?? Icons.refresh_outlined,
          size: 16, color: AppColors.primaryBlue),
      label: Text(label,
          style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
