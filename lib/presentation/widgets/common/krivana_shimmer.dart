import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';

class KrivanaShimmer extends StatelessWidget {
  const KrivanaShimmer({super.key, this.height = 100, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor:
          isDark ? AppColors.darkCard : AppColors.lightCard,
      highlightColor:
          isDark ? AppColors.darkBorder : AppColors.lightBorder,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
