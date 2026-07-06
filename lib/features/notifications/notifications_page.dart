import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/models/mobile_models.dart';
import '../../core/services/marketplace_repository.dart';
import '../../core/services/realtime_refresh_service.dart';
import '../../shared/mobile_ui.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final MarketplaceRepository _repo;
  late Future<List<AppNotification>> _future;
  RealtimeRefreshController? _realtime;

  @override
  void initState() {
    super.initState();
    _repo = MarketplaceRepository(Supabase.instance.client);
    _future = _repo.notifications();
    final userId = _repo.userId;
    if (userId != null) {
      _realtime = RealtimeRefreshController(
        client: Supabase.instance.client,
        channelName: 'notifications:$userId',
        onRefresh: _refresh,
      )..watchTable(
        'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
      );
      _realtime!.subscribe();
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _repo.notifications());
  }

  @override
  void dispose() {
    _realtime?.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    await _repo.markAllNotificationsRead();
    _refresh();
  }

  Future<void> _markRead(AppNotification item) async {
    if (item.isRead) return;
    await _repo.markNotificationRead(item.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9FF),
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Tandai dibaca',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingState(message: 'Memuat notifikasi...');
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: friendlyErrorMessage(snapshot.error),
              onRetry: _refresh,
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              message: 'Belum ada notifikasi',
              icon: Icons.notifications_none_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _NotificationCard(
                  item: item,
                  onTap: () => _markRead(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _notificationColor(item.type);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE7EEF7)
                  : color.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF234D79).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_notificationIcon(item.type), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _relativeTime(item.createdAt!),
                        style: const TextStyle(
                          color: Color(0xFF8A96AA),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _notificationColor(String type) {
  if (type.contains('payment')) return AppColors.success;
  if (type.contains('rejected')) return AppColors.danger;
  if (type.contains('order')) return AppColors.primary;
  return AppColors.secondary;
}

IconData _notificationIcon(String type) {
  if (type.contains('payment')) return Icons.payments_rounded;
  if (type.contains('rejected')) return Icons.cancel_rounded;
  if (type.contains('order')) return Icons.assignment_turned_in_rounded;
  return Icons.notifications_active_rounded;
}

String _relativeTime(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt.toLocal());
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
