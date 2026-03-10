import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../glass/glass_container.dart';
import '../svg/svg_icon.dart';

class KrivanaButton extends StatefulWidget {
  const KrivanaButton({
    super.key,
    required this.label,
    this.onTap,
    this.svgIconPath,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onTap;
  final String? svgIconPath;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<KrivanaButton> createState() => _KrivanaButtonState();
}

class _KrivanaButtonState extends State<KrivanaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onTap != null && !widget.isLoading;
    final bg = widget.backgroundColor ??
        (widget.isPrimary
            ? AppColors.accentPurple
            : (isDark ? AppColors.darkCard : AppColors.lightCard));
    final fg = widget.foregroundColor ??
        (widget.isPrimary
            ? Colors.white
            : (isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary));

    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              _press.forward();
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: enabled
          ? (_) {
              _press.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.width,
          child: GlassContainer(
            borderRadius: 50,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            tintOpacity: enabled
                ? (widget.isPrimary ? 0.08 : (isDark ? 0.06 : 0.10))
                : 0.03,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.svgIconPath != null) ...[
                  SvgIcon(widget.svgIconPath!, size: 18),
                  const SizedBox(width: 8),
                ],
                if (widget.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: enabled
                          ? bg
                          : bg.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      widget.label,
                      style: AppTextStyles.buttonLabel.copyWith(color: fg),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
