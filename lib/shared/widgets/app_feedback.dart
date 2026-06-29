import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AppFeedbackType { success, error, warning, info }

class AppFeedback {
  const AppFeedback._();

  static void success(
    BuildContext context, {
    String title = 'Berhasil',
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: AppFeedbackType.success,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void error(
    BuildContext context, {
    String title = 'Terjadi kendala',
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: AppFeedbackType.error,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 5),
    );
  }

  static void warning(
    BuildContext context, {
    String title = 'Perlu perhatian',
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: AppFeedbackType.warning,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void info(
    BuildContext context, {
    String title = 'Informasi',
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      type: AppFeedbackType.info,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void show(
    BuildContext context, {
    required AppFeedbackType type,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    Timer? timer;
    void close() {
      timer?.cancel();
      if (entry.mounted) entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) {
        return _FeedbackOverlay(
          type: type,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  close();
                  onAction();
                },
          onDismiss: close,
        );
      },
    );

    overlay.insert(entry);
    timer = Timer(duration, close);
  }
}

class AppFeedbackBanner extends StatelessWidget {
  const AppFeedbackBanner({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.compact = false,
  });

  final AppFeedbackType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = _FeedbackTokens.of(type);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final shake = type == AppFeedbackType.error
            ? math.sin(value * math.pi * 4) * (1 - value) * 8
            : 0.0;
        return Transform.translate(
          offset: Offset(shake, (1 - value) * 12),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tokens.softColor, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
          border: Border.all(color: tokens.borderColor),
          boxShadow: [
            BoxShadow(
              color: tokens.accentColor.withValues(alpha: 0.12),
              blurRadius: compact ? 14 : 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeedbackIcon(tokens: tokens, compact: compact),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: tokens.titleColor,
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        message,
                        style: TextStyle(
                          color: tokens.textColor,
                          fontSize: compact ? 12 : 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: onDismiss,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: tokens.textColor,
                      size: 20,
                    ),
                  ),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: Icon(tokens.actionIcon, size: 18),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppFeedbackDialog extends StatelessWidget {
  const AppFeedbackDialog({super.key, this.title, this.content, this.actions});

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7EEF7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF07143D).withValues(alpha: 0.16),
                blurRadius: 34,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Color(0xFF07143D),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                    child: title!,
                  ),
                ),
              if (content != null)
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      title == null ? 20 : 8,
                      22,
                      actions == null || actions!.isEmpty ? 22 : 14,
                    ),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: Color(0xFF475A78),
                        fontSize: 14,
                        height: 1.45,
                      ),
                      child: content!,
                    ),
                  ),
                ),
              if (actions != null && actions!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7FAFE),
                    border: Border(top: BorderSide(color: Color(0xFFE7EEF7))),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: actions!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackOverlay extends StatelessWidget {
  const _FeedbackOverlay({
    required this.type,
    required this.title,
    required this.message,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  final AppFeedbackType type;
  final String title;
  final String message;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom + 18;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppFeedbackBanner(
              type: type,
              title: title,
              message: message,
              actionLabel: actionLabel,
              onAction: onAction,
              onDismiss: onDismiss,
              compact: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackIcon extends StatelessWidget {
  const _FeedbackIcon({required this.tokens, required this.compact});

  final _FeedbackTokens tokens;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.accentColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        tokens.icon,
        color: tokens.accentColor,
        size: compact ? 22 : 25,
      ),
    );
  }
}

class _FeedbackTokens {
  const _FeedbackTokens({
    required this.icon,
    required this.actionIcon,
    required this.accentColor,
    required this.softColor,
    required this.borderColor,
    required this.titleColor,
    required this.textColor,
  });

  final IconData icon;
  final IconData actionIcon;
  final Color accentColor;
  final Color softColor;
  final Color borderColor;
  final Color titleColor;
  final Color textColor;

  static _FeedbackTokens of(AppFeedbackType type) {
    return switch (type) {
      AppFeedbackType.success => const _FeedbackTokens(
        icon: Icons.check_circle_rounded,
        actionIcon: Icons.arrow_forward_rounded,
        accentColor: Color(0xFF16A34A),
        softColor: Color(0xFFEFFBF3),
        borderColor: Color(0xFFC9F2D5),
        titleColor: Color(0xFF052E16),
        textColor: Color(0xFF3D6B4B),
      ),
      AppFeedbackType.error => const _FeedbackTokens(
        icon: Icons.lock_reset_rounded,
        actionIcon: Icons.refresh_rounded,
        accentColor: Color(0xFFE5484D),
        softColor: Color(0xFFFFF5F5),
        borderColor: Color(0xFFFFC9C9),
        titleColor: Color(0xFF07143D),
        textColor: Color(0xFF805255),
      ),
      AppFeedbackType.warning => const _FeedbackTokens(
        icon: Icons.report_problem_rounded,
        actionIcon: Icons.tune_rounded,
        accentColor: Color(0xFFF59E0B),
        softColor: Color(0xFFFFFAEB),
        borderColor: Color(0xFFFDE4A8),
        titleColor: Color(0xFF3B2A05),
        textColor: Color(0xFF80622D),
      ),
      AppFeedbackType.info => const _FeedbackTokens(
        icon: Icons.info_rounded,
        actionIcon: Icons.open_in_new_rounded,
        accentColor: Color(0xFF0876ED),
        softColor: Color(0xFFEAF4FF),
        borderColor: Color(0xFFC9DEFF),
        titleColor: Color(0xFF07143D),
        textColor: Color(0xFF475A78),
      ),
    };
  }
}
