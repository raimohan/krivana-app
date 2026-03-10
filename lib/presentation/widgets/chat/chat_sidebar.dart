import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

class ChatSidebar extends StatelessWidget {
  const ChatSidebar({
    super.key,
    required this.sessions,
    required this.pinnedSessions,
    required this.onNewChat,
    required this.onSelectSession,
    required this.onClose,
    this.onDeleteSession,
    this.onPinSession,
  });

  final List<ChatSession> sessions;
  final List<ChatSession> pinnedSessions;
  final VoidCallback onNewChat;
  final ValueChanged<String> onSelectSession;
  final VoidCallback onClose;
  final ValueChanged<String>? onDeleteSession;
  final ValueChanged<String>? onPinSession;

  Map<String, List<ChatSession>> _categorize() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = <ChatSession>[];
    final yesterdayList = <ChatSession>[];
    final previousList = <ChatSession>[];

    for (final s in sessions) {
      final created = s.createdAt ?? DateTime(2000);
      if (created.isAfter(today)) {
        todayList.add(s);
      } else if (created.isAfter(yesterday)) {
        yesterdayList.add(s);
      } else {
        previousList.add(s);
      }
    }

    return {
      'Today': todayList,
      'Yesterday': yesterdayList,
      'Previous': previousList,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _categorize();

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) onClose();
      },
      child: Container(
        width: 280,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: Border(
            right: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // New chat button
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onNewChat();
                  },
                  child: GlassContainer(
                    borderRadius: 50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KrivanaSvg(SvgPaths.icPlus, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'New Chat',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Chat list by categories
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final entry in categories.entries)
                      if (entry.value.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 4, top: 12, bottom: 6),
                          child: Text(
                            entry.key,
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        ...entry.value.map((session) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: GestureDetector(
                                onTap: () => onSelectSession(session.id),
                                onLongPress: () {
                                  HapticFeedback.mediumImpact();
                                  _showSessionMenu(context, session);
                                },
                                child: GlassContainer(
                                  borderRadius: 12,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      if (session.isPinned)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: KrivanaSvg(SvgPaths.icPin,
                                              size: 12,
                                              color: AppColors.accentPurple),
                                        ),
                                      Expanded(
                                        child: Text(
                                          session.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 13,
                                            color: isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                      ],
                  ],
                ),
              ),

              // View all at bottom
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: onClose,
                  child: Text(
                    'View All',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionMenu(BuildContext context, ChatSession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: KrivanaSvg(SvgPaths.icPin, size: 20),
                title: Text(
                  session.isPinned ? 'Unpin' : 'Pin',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onPinSession?.call(session.id);
                },
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icTrash, size: 20,
                    color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteSession?.call(session.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
