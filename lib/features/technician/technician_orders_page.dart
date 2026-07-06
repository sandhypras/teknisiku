import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../shared/mobile_ui.dart';
import '../../shared/widgets/app_feedback.dart';

class TechnicianOrdersPage extends StatefulWidget {
  const TechnicianOrdersPage({required this.repo, super.key});

  final MarketplaceRepository repo;

  @override
  State<TechnicianOrdersPage> createState() => _TechnicianOrdersPageState();
}

class _TechnicianOrdersPageState extends State<TechnicianOrdersPage> {
  late Future<_TechnicianOrdersData> _future;
  final _picker = ImagePicker();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TechnicianOrdersData> _load() async {
    final technician = await widget.repo.myTechnicianProfile();
    final orders = technician == null
        ? <OrderSummary>[]
        : await widget.repo.technicianOrders(technician.id);
    return _TechnicianOrdersData(technician: technician, orders: orders);
  }

  void _refresh() => setState(() {
    _future = _load();
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F8FF), Color(0xFFFAFCFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_TechnicianOrdersData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data!;
            final filtered = _filtered(data.orders);
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  const _OrdersHeader(),
                  const SizedBox(height: 18),
                  _OrderTabs(
                    selected: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                  const SizedBox(height: 18),
                  if (data.technician == null)
                    const SizedBox(
                      height: 320,
                      child: EmptyState(
                        message: 'Lengkapi profil teknisi dulu',
                        icon: Icons.badge_outlined,
                      ),
                    )
                  else if (filtered.isEmpty)
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: EmptyState(
                        message: _emptyMessage,
                        icon: Icons.assignment_outlined,
                      ),
                    )
                  else
                    for (final order in filtered) ...[
                      _OrderCard(
                        order: order,
                        onStatus: (status) async {
                          await _updateOrderStatus(order, status);
                        },
                        onDetail: () => _showOrderDetail(order),
                        onDiagnosis: () => _showDiagnosisSheet(order),
                        onUploadBefore: () =>
                            _showPhotoSource(order, 'Foto sebelum pengerjaan'),
                        onUploadAfter: () =>
                            _showPhotoSource(order, 'Foto sesudah pengerjaan'),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(OrderSummary order, String status) async {
    try {
      if (status == 'completed') {
        await widget.repo.completeOrderWithDocuments(order.id);
      } else {
        await widget.repo.updateOrderStatus(order.id, status);
      }
      if (!mounted) return;
      AppFeedback.success(
        context,
        title: 'Status diperbarui',
        message: 'Order berubah ke ${orderStatusLabel(status)}.',
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        title: 'Gagal memperbarui order',
        message: friendlyErrorMessage(error),
      );
    }
  }

  String get _emptyMessage => switch (_tab) {
    1 => 'Belum ada order yang sedang diproses',
    2 => 'Belum ada order selesai',
    3 => 'Belum ada order ditolak',
    _ => 'Belum ada order baru',
  };

  List<OrderSummary> _filtered(List<OrderSummary> orders) {
    return switch (_tab) {
      1 =>
        orders
            .where(
              (item) =>
                  item.status != 'waiting_confirmation' &&
                  item.status != 'completed' &&
                  item.status != 'rejected' &&
                  item.status != 'price_rejected',
            )
            .toList(),
      2 => orders.where((item) => item.status == 'completed').toList(),
      3 =>
        orders
            .where(
              (item) =>
                  item.status == 'rejected' || item.status == 'price_rejected',
            )
            .toList(),
      _ =>
        orders.where((item) => item.status == 'waiting_confirmation').toList(),
    };
  }

  void _showOrderDetail(OrderSummary order) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    final addressText = [
      order.address,
      order.city,
    ].where((item) => (item ?? '').trim().isNotEmpty).join(', ');
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                _DetailLine('Customer', order.customerName),
                _CopyableDetailLine('Telepon', order.customerPhone ?? '-'),
                _DetailLine('Status', orderStatusLabel(order.status)),
                _DetailLine(
                  'Jadwal',
                  '${order.scheduleDate} ${order.scheduleTime}',
                ),
                _DetailLine(
                  'Alamat',
                  addressText.isEmpty
                      ? 'Alamat belum tersedia di data pesanan'
                      : addressText,
                ),
                if (order.serviceFee > 0)
                  _DetailLine('Biaya layanan', formatRupiah(order.serviceFee)),
                _DetailLine('Estimasi', formatRupiah(total)),
                const Divider(height: 26),
                const Text(
                  'Deskripsi Masalah',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.problemDescription.isEmpty
                      ? 'Tidak ada deskripsi'
                      : order.problemDescription,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                FutureBuilder<OrderWorkflowDetail>(
                  future: widget.repo.orderWorkflowDetail(order.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(friendlyErrorMessage(snapshot.error));
                    }
                    return _WorkflowDetailPanel(detail: snapshot.data!);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiagnosisSheet(OrderSummary order) {
    final diagnosisCtrl = TextEditingController();
    final estimationCtrl = TextEditingController();
    final serviceCostCtrl = TextEditingController(
      text: order.finalTotal > 0 ? order.finalTotal.toStringAsFixed(0) : '',
    );
    final parts = <_SparepartDraft>[_SparepartDraft()];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnosis & Estimasi Final',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: diagnosisCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis kerusakan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: estimationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Estimasi pengerjaan',
                    hintText: 'Contoh: 1-2 hari',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: serviceCostCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Biaya jasa final',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sparepart',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setSheetState(() => parts.add(_SparepartDraft())),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
                for (final entry in parts.indexed) ...[
                  _SparepartInputRow(
                    draft: entry.$2,
                    onRemove: parts.length == 1
                        ? null
                        : () => setSheetState(() => parts.removeAt(entry.$1)),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Kirim Estimasi ke Customer'),
                    onPressed: () async {
                      if (diagnosisCtrl.text.trim().isEmpty) {
                        AppFeedback.warning(
                          context,
                          title: 'Diagnosis wajib diisi',
                          message:
                              'Tuliskan hasil pemeriksaan sebelum mengirim estimasi.',
                        );
                        return;
                      }
                      try {
                        await widget.repo.submitOrderDiagnosis(
                          orderId: order.id,
                          diagnosisResult: diagnosisCtrl.text.trim(),
                          workEstimation: estimationCtrl.text.trim(),
                          serviceCost:
                              double.tryParse(
                                serviceCostCtrl.text.trim().replaceAll('.', ''),
                              ) ??
                              0,
                          spareparts: parts
                              .map((part) => part.toPayload())
                              .where(
                                (item) =>
                                    '${item['name'] ?? ''}'.trim().isNotEmpty,
                              )
                              .toList(),
                        );
                        if (!mounted) return;
                        if (context.mounted) Navigator.pop(context);
                        AppFeedback.success(
                          this.context,
                          title: 'Estimasi dikirim',
                          message:
                              'Customer dapat menyetujui atau menolak biaya final.',
                        );
                        _refresh();
                      } catch (error) {
                        if (!context.mounted) return;
                        AppFeedback.error(
                          context,
                          title: 'Gagal mengirim estimasi',
                          message: friendlyErrorMessage(error),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPhotoSource(OrderSummary order, String caption) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Ambil dari kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadWorkPhoto(order, caption, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadWorkPhoto(order, caption, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadWorkPhoto(
    OrderSummary order,
    String caption,
    ImageSource source,
  ) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (file == null) return;
    try {
      await widget.repo.uploadOrderAttachment(
        orderId: order.id,
        bytes: await file.readAsBytes(),
        fileName: file.name,
        contentType: file.mimeType,
        caption: caption,
      );
      if (!mounted) return;
      AppFeedback.success(context, title: 'Foto terupload', message: caption);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.error(
        context,
        title: 'Upload foto gagal',
        message: friendlyErrorMessage(error),
      );
    }
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogoMark(size: 58),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Saya',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Kelola pekerjaan teknisi dari Supabase',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: _cardDecoration(radius: 15),
          child: const Icon(Icons.assignment_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Baru', 'Proses', 'Selesai', 'Ditolak'];
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: _cardDecoration(radius: 14),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(11),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == index
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected == index
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onStatus,
    required this.onDetail,
    required this.onDiagnosis,
    required this.onUploadBefore,
    required this.onUploadAfter,
  });

  final OrderSummary order;
  final ValueChanged<String> onStatus;
  final VoidCallback onDetail;
  final VoidCallback onDiagnosis;
  final VoidCallback onUploadBefore;
  final VoidCallback onUploadAfter;

  @override
  Widget build(BuildContext context) {
    final total = order.finalTotal > 0
        ? order.finalTotal
        : order.estimatedTotal;
    final statusColor = orderStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusPill(
                label: orderStatusLabel(order.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  categoryIcon(order.problemDescription),
                  color: AppColors.primary,
                  size: 39,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.problemDescription.isEmpty
                          ? 'Permintaan Layanan'
                          : order.problemDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _MetaLine(
                      icon: Icons.person_outline_rounded,
                      text: [
                        order.customerName,
                        order.customerPhone,
                      ].where((item) => (item ?? '').isNotEmpty).join(' - '),
                    ),
                    _MetaLine(
                      icon: Icons.location_on_outlined,
                      text: [
                        order.address,
                        order.city,
                      ].where((item) => (item ?? '').isNotEmpty).join(', '),
                    ),
                    _MetaLine(
                      icon: Icons.calendar_month_outlined,
                      text: '${order.scheduleDate} ${order.scheduleTime}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                formatRupiah(total),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onDetail, child: const Text('Detail')),
            ],
          ),
          _ActionRow(
            order: order,
            onStatus: onStatus,
            onDiagnosis: onDiagnosis,
            onUploadBefore: onUploadBefore,
            onUploadAfter: onUploadAfter,
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.order,
    required this.onStatus,
    required this.onDiagnosis,
    required this.onUploadBefore,
    required this.onUploadAfter,
  });

  final OrderSummary order;
  final ValueChanged<String> onStatus;
  final VoidCallback onDiagnosis;
  final VoidCallback onUploadBefore;
  final VoidCallback onUploadAfter;

  @override
  Widget build(BuildContext context) {
    if (order.status == 'waiting_confirmation') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onStatus('rejected'),
              child: const Text('Tolak'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => onStatus('accepted'),
              child: const Text('Terima'),
            ),
          ),
        ],
      );
    }
    if (order.status == 'inspection' ||
        order.status == 'waiting_price_approval') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDiagnosis,
              icon: const Icon(Icons.build_circle_rounded),
              label: Text(
                order.status == 'waiting_price_approval'
                    ? 'Edit Diagnosis & Biaya'
                    : 'Isi Diagnosis & Biaya',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUploadBefore,
                  icon: const Icon(Icons.photo_camera_rounded, size: 17),
                  label: const Text('Foto Sebelum'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUploadAfter,
                  icon: const Icon(Icons.photo_library_rounded, size: 17),
                  label: const Text('Foto Sesudah'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (order.status == 'in_progress') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUploadBefore,
                  icon: const Icon(Icons.photo_camera_rounded, size: 17),
                  label: const Text('Foto Sebelum'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUploadAfter,
                  icon: const Icon(Icons.photo_library_rounded, size: 17),
                  label: const Text('Foto Sesudah'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onStatus('waiting_payment'),
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Selesai, Minta Pembayaran'),
            ),
          ),
        ],
      );
    }
    final next = _nextStatus(order.status);
    if (next == order.status) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => onStatus(next),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text('Ubah ke ${orderStatusLabel(next)}'),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowDetailPanel extends StatelessWidget {
  const _WorkflowDetailPanel({required this.detail});

  final OrderWorkflowDetail detail;

  @override
  Widget build(BuildContext context) {
    final diagnosis = detail.diagnosis;
    if (diagnosis == null &&
        detail.spareparts.isEmpty &&
        detail.attachments.isEmpty) {
      return const Text(
        'Diagnosis, sparepart, dan foto pekerjaan belum ditambahkan.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (diagnosis != null) ...[
          const Text(
            'Diagnosis',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(diagnosis.diagnosisResult),
          if ((diagnosis.workEstimation ?? '').isNotEmpty)
            Text('Estimasi: ${diagnosis.workEstimation}'),
          Text('Biaya jasa: ${formatRupiah(diagnosis.serviceCost)}'),
          Text('Biaya sparepart: ${formatRupiah(diagnosis.sparepartCost)}'),
          Text(
            'Total: ${formatRupiah(diagnosis.totalCost)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const Divider(height: 24),
        ],
        if (detail.spareparts.isNotEmpty) ...[
          const Text(
            'Sparepart',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          for (final item in detail.spareparts)
            Text(
              '${item.name} x${item.quantity} - ${formatRupiah(item.total)}',
            ),
          const Divider(height: 24),
        ],
        if (detail.attachments.isNotEmpty) ...[
          const Text(
            'Foto Pekerjaan',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final attachment = detail.attachments[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.network(
                        attachment.fileUrl,
                        width: 110,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 110,
                          height: 96,
                          color: const Color(0xFFEAF4FF),
                          child: const Icon(Icons.broken_image_rounded),
                        ),
                      ),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Text(
                          attachment.caption ?? 'Foto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SparepartDraft {
  final name = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final price = TextEditingController();

  Map<String, dynamic> toPayload() {
    return {
      'name': name.text.trim(),
      'quantity': int.tryParse(quantity.text.trim()) ?? 1,
      'unit_price': double.tryParse(price.text.trim().replaceAll('.', '')) ?? 0,
    };
  }
}

class _SparepartInputRow extends StatelessWidget {
  const _SparepartInputRow({required this.draft, this.onRemove});

  final _SparepartDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TextField(
            controller: draft.name,
            decoration: const InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: draft.quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Qty',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: draft.price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Harga',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableDetailLine extends StatelessWidget {
  const _CopyableDetailLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final canCopy = value.trim().isNotEmpty && value != '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Salin nomor telepon',
            visualDensity: VisualDensity.compact,
            onPressed: canCopy
                ? () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!context.mounted) return;
                    AppFeedback.success(
                      context,
                      title: 'Nomor disalin',
                      message: 'Nomor telepon customer sudah disalin.',
                    );
                  }
                : null,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _TechnicianOrdersData {
  const _TechnicianOrdersData({required this.technician, required this.orders});

  final TechnicianSummary? technician;
  final List<OrderSummary> orders;
}

String _nextStatus(String status) => switch (status) {
  'accepted' => 'on_the_way',
  'on_the_way' => 'inspection',
  'in_progress' => 'waiting_payment',
  _ => status,
};

BoxDecoration _cardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE4ECF6)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF234D79).withValues(alpha: 0.08),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
