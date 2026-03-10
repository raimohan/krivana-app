import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.blurStrength = 20,
    this.tintOpacity,
    this.borderOpacity,
    this.width,
    this.height,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurStrength;
  final double? tintOpacity;
  final double? borderOpacity;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTint = tintOpacity ?? (isDark ? 0.07 : 0.06);
    final effectiveBorder = borderOpacity ?? (isDark ? 0.12 : 0.15);

    final tintColor = isDark
        ? Colors.white.withValues(alpha: effectiveTint)
        : Colors.black.withValues(alpha: effectiveTint);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: effectiveBorder)
        : Colors.black.withValues(alpha: effectiveBorder);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter:
            ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: tintColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
