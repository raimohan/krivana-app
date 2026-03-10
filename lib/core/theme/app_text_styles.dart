import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  static const splashTitle = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static const heading1 = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const heading2 = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const body = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.darkTextSecondary,
  );

  static const buttonLabel = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const chatGreeting = TextStyle(
    fontFamily: 'Brockmann',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const codeBlock = TextStyle(
    fontFamily: 'Courier New',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFFA0D0FF),
  );

  static TextTheme get dark => const TextTheme(
        displayLarge: heading1,
        titleLarge: heading2,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: buttonLabel,
      );

  static TextTheme get light => TextTheme(
        displayLarge: heading1.copyWith(color: AppColors.lightTextPrimary),
        titleLarge: heading2.copyWith(color: AppColors.lightTextPrimary),
        bodyMedium: body.copyWith(color: AppColors.lightTextPrimary),
        bodySmall: caption.copyWith(color: AppColors.lightTextSecondary),
        labelLarge: buttonLabel.copyWith(color: AppColors.lightTextPrimary),
      );
}
