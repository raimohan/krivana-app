import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'krivana_svg.dart';

class SvgAvatar extends StatelessWidget {
  const SvgAvatar(
    this.assetPath, {
    super.key,
    this.radius = 18,
    this.backgroundColor,
  });

  final String assetPath;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.glassSurface,
      child: KrivanaSvg(assetPath, size: radius * 1.1, autoTheme: true),
    );
  }
}
