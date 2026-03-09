import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  });

  final String label;
  final VoidCallback? onTap;
  final String? svgIconPath;
  final bool isPrimary;
  final bool isLoading;
  final double? width;

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
    return GestureDetector(
      onTapDown: (_) {
        _press.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _press.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: widget.width,
          child: GlassContainer(
            borderRadius: 50,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            tintOpacity: widget.isPrimary ? 0.12 : 0.05,
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
                  Text(widget.label, style: AppTextStyles.buttonLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
