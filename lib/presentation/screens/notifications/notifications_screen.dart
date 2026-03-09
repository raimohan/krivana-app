import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../widgets/glass/glass_container.dart';

final _notificationsProvider =
    StateProvider<List<AppNotification>>((ref) {
  final box = Hive.box(AppConstants.hiveNotificationsBox);
  final raw = box.values.toList();
  if (raw.isEmpty) {
    // Pre-seed welcome notification
    return [
      AppNotification(
        id: '1',
        title: 'Welcome to Krivana! 🎉',
        body: 'Get started by creating your first project or importing'
            ' a repo from GitHub.',
        type: NotificationType.system,
        createdAt: DateTime.now(),
      ),
    ];
  }
  return raw
      .whereType<Map>()
      .map((e) =>
          AppNotification.fromJson(Map<String, dynamic>.from(e)))
      .toList()
    ..sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifications = ref.watch(_notificationsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: SvgPicture.asset(SvgPaths.icBack,
                        width: 24, height: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: AppTextStyles.heading2.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  if (notifications.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref.read(_notificationsProvider.notifier).state = [];
                        final box =
                            Hive.box(AppConstants.hiveNotificationsBox);
                        box.clear();
                      },
                      child: Text(
                        'Clear All',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(SvgPaths.icNotifications,
                              width: 48, height: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: AppTextStyles.body.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final n = notifications[index];
                        return _NotificationTile(
                          notification: n,
                          onTap: () {
                            if (!n.isRead) {
                              final updated = List<AppNotification>.from(
                                  notifications);
                              updated[index] = n.copyWith(isRead: true);
                              ref
                                  .read(_notificationsProvider.notifier)
                                  .state = updated;
                            }
                          },
                          onDismiss: () {
                            final updated = List<AppNotification>.from(
                                notifications)
                              ..removeAt(index);
                            ref.read(_notificationsProvider.notifier).state =
                                updated;
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  IconData get _icon => switch (notification.type) {
        NotificationType.update => Icons.system_update_rounded,
        NotificationType.deploy => Icons.rocket_launch_rounded,
        NotificationType.ai => Icons.auto_awesome_rounded,
        NotificationType.github => Icons.code_rounded,
        NotificationType.system => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          tintOpacity: notification.isRead ? 0.03 : 0.07,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, size: 22, color: AppColors.accentPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.accentPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
