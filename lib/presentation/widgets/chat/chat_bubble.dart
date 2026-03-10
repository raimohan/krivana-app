import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

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
            KrivanaSvg(SvgPaths.avatarAiKrivana, size: 28, autoTheme: false),
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
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AnimatedActionIcon(
                      svgPath: SvgPaths.icCopy,
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: message.content));
                        onCopy?.call();
                      },
                    ),
                    if (!isUser) ...[
                      const SizedBox(width: 8),
                      _AnimatedActionIcon(
                        svgPath: SvgPaths.icRegenerate,
                        onTap: onRegenerate,
                      ),
                      const SizedBox(width: 8),
                      _AnimatedActionIcon(
                        svgPath: SvgPaths.icLike,
                        onTap: onLike,
                        fillOnTap: true,
                        activeColor: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      _AnimatedActionIcon(
                        svgPath: SvgPaths.icDislike,
                        onTap: onDislike,
                        fillOnTap: true,
                        activeColor: AppColors.error,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            KrivanaSvg(SvgPaths.avatarUserDefault, size: 28),
          ],
        ],
      ),
    );
  }
}

class _AnimatedActionIcon extends StatefulWidget {
  final String svgPath;
  final VoidCallback? onTap;
  final bool fillOnTap;
  final Color? activeColor;

  const _AnimatedActionIcon({
    required this.svgPath,
    this.onTap,
    this.fillOnTap = false,
    this.activeColor,
  });

  @override
  State<_AnimatedActionIcon> createState() => _AnimatedActionIconState();
}

class _AnimatedActionIconState extends State<_AnimatedActionIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _controller.forward(from: 0);
        if (widget.fillOnTap) {
          setState(() => _isActive = !_isActive);
        }
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: KrivanaSvg(
            widget.svgPath,
            size: 16,
            color: _isActive ? widget.activeColor : null,
          ),
        ),
      ),
    );
  }
}
