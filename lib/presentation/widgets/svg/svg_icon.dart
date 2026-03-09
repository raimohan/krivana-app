import 'package:flutter/material.dart';
import 'krivana_svg.dart';

class SvgIcon extends StatelessWidget {
  const SvgIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
  });

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      KrivanaSvg(assetPath, size: size, color: color);
}
