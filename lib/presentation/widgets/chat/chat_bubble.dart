import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/svg_icon.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRegenerate,
    this.onLike,
    this.onDislike,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI avatar
            const SvgIcon(SvgPaths.avatarAiKrivana, size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  borderRadius: 16,
                  tintOpacity: isUser ? 0.10 : 0.05,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: isUser
                      ? Text(
                          message.content,
                          style: AppTextStyles.body.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: AppTextStyles.body.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A1A2E)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            code: AppTextStyles.codeBlock,
                          ),
                        ),
                ),

                // Actions
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionIcon(
                      svgPath: SvgPaths.icCopy,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: message.content));
                        onCopy?.call();
                      },
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 8),
                      _ActionIcon(
                        svgPath: SvgPaths.icRegenerate,
                        onTap: onRegenerate,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        svgPath: SvgPaths.icLike,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 8),
                      _ActionIcon(
                        svgPath: SvgPaths.icDislike,
                        onTap: onDislike,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const SvgIcon(SvgPaths.avatarUserDefault, size: 28),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String svgPath;
  final VoidCallback? onTap;

  const _ActionIcon({required this.svgPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SvgIcon(svgPath, size: 16),
      ),
    );
  }
}
