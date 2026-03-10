import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KrivanaSvg extends StatelessWidget {
  const KrivanaSvg(
    this.assetPath, {
    super.key,
    this.size,
    this.width,
    this.height,
    this.color,
    this.autoTheme = true,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.animate = true,
  });

  final String assetPath;
  final double? size;
  final double? width;
  final double? height;
  final Color? color;
  final bool autoTheme;
  final BoxFit fit;
  final String? semanticLabel;
  final bool animate;

  /// Brand logos (providers, social) should keep their original colors
  static bool _isBrandLogo(String path) {
    return path.contains('providers/') ||
        path.contains('social/') ||
        path.contains('avatars/avatar_ai');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color? resolvedColor;
    if (color != null) {
      resolvedColor = color;
    } else if (autoTheme && !_isBrandLogo(assetPath)) {
      resolvedColor = isDark ? Colors.white : Colors.black87;
    }

    final icon = SvgPicture.asset(
      assetPath,
      width: size ?? width,
      height: size ?? height,
      fit: fit,
      semanticsLabel: semanticLabel,
      colorFilter: resolvedColor != null
          ? ColorFilter.mode(resolvedColor, BlendMode.srcIn)
          : null,
    );

    if (!animate) return icon;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.45 + (value * 0.55),
          child: Transform.scale(
            scale: 0.95 + (value * 0.05),
            child: child,
          ),
        );
      },
      child: icon,
    );
  }
}
