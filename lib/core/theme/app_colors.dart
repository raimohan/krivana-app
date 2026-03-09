import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Dark Theme ───────────────────────────────
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF0A0A0A);
  static const darkCard = Color(0xFF111111);
  static const darkBorder = Color(0xFF1F1F1F);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFA0A0A0);
  static const darkTextMuted = Color(0xFF505050);

  // ── Light Theme ──────────────────────────────
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F5F5);
  static const lightCard = Color(0xFFEFEFEF);
  static const lightBorder = Color(0xFFE0E0E0);
  static const lightTextPrimary = Color(0xFF000000);
  static const lightTextSecondary = Color(0xFF606060);

  // ── Brand ────────────────────────────────────
  static const accentPurple = Color(0xFF7C3AED);
  static const accentPink = Color(0xFFEC4899);
  static const githubCardPurple = Color(0xFF4C1D95);

  // ── Semantic ─────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);

  // ── Glass ────────────────────────────────────
  static const glassSurface = Color(0x0FFFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const glassHighlight = Color(0x33FFFFFF);
}
