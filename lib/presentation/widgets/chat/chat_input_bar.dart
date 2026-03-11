import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttach,
    this.onModelSelect,
    this.hintText = 'Type a message...',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final VoidCallback? onModelSelect;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _InputCircleButton(
            onTap: onAttach,
            iconPath: SvgPaths.icUpload,
          ),
          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                textAlignVertical: TextAlignVertical.center,
                strutStyle: const StrutStyle(height: 1.35, forceStrutHeight: true),
                style: AppTextStyles.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextSecondary,
                    height: 1.35,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          _InputCircleButton(
            onTap: onModelSelect,
            iconPath: SvgPaths.icSettings,
          ),
          const SizedBox(width: 8),

          _InputCircleButton(
            onTap: () {
              if (controller.text.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                onSend();
              }
            },
            iconPath: SvgPaths.icSend,
            tintOpacity: 0.12,
          ),
        ],
      ),
    );
  }
}

class _InputCircleButton extends StatelessWidget {
  const _InputCircleButton({
    required this.iconPath,
    required this.onTap,
    this.tintOpacity = 0.08,
  });

  final String iconPath;
  final VoidCallback? onTap;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassContainer(
        borderRadius: 50,
        padding: EdgeInsets.zero,
        tintOpacity: tintOpacity,
        width: 38,
        height: 38,
        child: Center(
          child: KrivanaSvg(iconPath, size: 18),
        ),
      ),
    );
  }
}
