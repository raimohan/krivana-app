import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class KrivanaThemeExtension extends ThemeExtension<KrivanaThemeExtension> {
  const KrivanaThemeExtension({
    required this.cardColor,
    required this.borderColor,
    required this.glassColor,
    required this.glassBorderColor,
  });

  final Color cardColor;
  final Color borderColor;
  final Color glassColor;
  final Color glassBorderColor;

  static const dark = KrivanaThemeExtension(
    cardColor: AppColors.darkCard,
    borderColor: AppColors.darkBorder,
    glassColor: AppColors.glassSurface,
    glassBorderColor: AppColors.glassBorder,
  );

  static const light = KrivanaThemeExtension(
    cardColor: AppColors.lightCard,
    borderColor: AppColors.lightBorder,
    glassColor: Color(0x0F000000),
    glassBorderColor: Color(0x1F000000),
  );

  @override
  KrivanaThemeExtension copyWith({
    Color? cardColor,
    Color? borderColor,
    Color? glassColor,
    Color? glassBorderColor,
  }) {
    return KrivanaThemeExtension(
      cardColor: cardColor ?? this.cardColor,
      borderColor: borderColor ?? this.borderColor,
      glassColor: glassColor ?? this.glassColor,
      glassBorderColor: glassBorderColor ?? this.glassBorderColor,
    );
  }

  @override
  KrivanaThemeExtension lerp(
      covariant KrivanaThemeExtension? other, double t) {
    if (other == null) return this;
    return KrivanaThemeExtension(
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      glassColor: Color.lerp(glassColor, other.glassColor, t)!,
      glassBorderColor:
          Color.lerp(glassBorderColor, other.glassBorderColor, t)!,
    );
  }
}

class AppTheme {
  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentPurple,
          surface: AppColors.darkSurface,
          error: AppColors.error,
        ),
        fontFamily: 'Brockmann',
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        textTheme: AppTextStyles.dark,
        extensions: const [KrivanaThemeExtension.dark],
      );

  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentPurple,
          surface: AppColors.lightSurface,
          error: AppColors.error,
        ),
        fontFamily: 'Brockmann',
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        textTheme: AppTextStyles.light,
        extensions: const [KrivanaThemeExtension.light],
      );
}
