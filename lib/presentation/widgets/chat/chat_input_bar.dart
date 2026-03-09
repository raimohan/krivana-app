import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/glass/glass_container.dart';

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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach button
          GestureDetector(
            onTap: onAttach,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SvgPicture.asset(SvgPaths.icUpload,
                  width: 22, height: 22),
            ),
          ),
          const SizedBox(width: 10),

          // Text field
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
              child: TextField(
                controller: controller,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: AppTextStyles.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: AppTextStyles.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Model selector
          GestureDetector(
            onTap: onModelSelect,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SvgPicture.asset(SvgPaths.icSettings,
                  width: 20, height: 20),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: () {
              if (controller.text.trim().isNotEmpty) {
                HapticFeedback.lightImpact();
                onSend();
              }
            },
            child: GlassContainer(
              borderRadius: 50,
              padding: const EdgeInsets.all(10),
              tintOpacity: 0.12,
              child:
                  SvgPicture.asset(SvgPaths.icSend, width: 18, height: 18),
            ),
          ),
        ],
      ),
    );
  }
}
