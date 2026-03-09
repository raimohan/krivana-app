import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/glass/glass_container.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        SvgPicture.asset(SvgPaths.icPlus,
                            width: 16, height: 16),
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

              // Chat list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sessions.length,
                  itemBuilder: (_, index) {
                    final session = sessions[index];
                    return GestureDetector(
                      onTap: () => onSelectSession(session.id),
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        _showSessionMenu(context, session);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GlassContainer(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          tintOpacity: 0.04,
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
                      ),
                    );
                  },
                ),
              ),

              // Pinned section
              if (pinnedSessions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pinned',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: pinnedSessions.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final pinned = pinnedSessions[index];
                      return GestureDetector(
                        onTap: () => onSelectSession(pinned.id),
                        child: GlassContainer(
                          borderRadius: 12,
                          padding: const EdgeInsets.all(10),
                          child: SizedBox(
                            width: 80,
                            child: Text(
                              pinned.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
      builder: (_) => GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icPin,
                  width: 20, height: 20),
              title: Text(session.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                Navigator.pop(context);
                onPinSession?.call(session.id);
              },
            ),
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icEdit,
                  width: 20, height: 20),
              title: const Text('Edit title'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icTrash,
                  width: 20, height: 20),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDeleteSession?.call(session.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
