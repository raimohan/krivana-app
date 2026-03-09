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
  });

  final String assetPath;
  final double? size;
  final double? width;
  final double? height;
  final Color? color;
  final bool autoTheme;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        color ?? (autoTheme ? (isDark ? Colors.white : Colors.black) : null);

    return SvgPicture.asset(
      assetPath,
      width: size ?? width,
      height: size ?? height,
      fit: fit,
      semanticsLabel: semanticLabel,
      colorFilter: resolvedColor != null
          ? ColorFilter.mode(resolvedColor, BlendMode.srcIn)
          : null,
    );
  }
}
