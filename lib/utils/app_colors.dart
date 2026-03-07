import 'package:flutter/material.dart';

/// ألوان التطبيق الموحدة
/// Unified app color constants
class AppColors {
  // الألوان الأساسية - Core Palette
  static const Color emerald = Color(0xFF03251D); // Deep Emerald
  static const Color emeraldLight = Color(0xFF0A4D3A);
  static const Color gold = Color(0xFFB8860B); // Premium Dark Gold
  static const Color goldAccent = Color(0xFFD4AF37); // Classic Gold
  static const Color cream = Color(0xFFFDF9F0); // Mushaf Page Background

  // ألوان الواجهة - UI Colors
  static const Color background = Color(0xFF021612);
  static const Color cardBackground = Color(0xFF0A2E26);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);

  // زجاجي (Glassmorphism)
  static Color glassBackground = Colors.white.withValues(alpha: 0.1);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);
  static Color glassBackgroundDark = Colors.black.withValues(alpha: 0.4);

  // Legacy support
  static const Color divider = emeraldLight;
}
