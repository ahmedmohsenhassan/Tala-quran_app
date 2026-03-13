import 'package:flutter/material.dart';

/// ألوان التطبيق الموحدة
/// Unified app color constants — Dark + Light mode support
class AppColors {
  // ============================================================
  //  الوضع الداكن (Dark Mode) — الألوان الأصلية
  // ============================================================

  // ============================================================
  //  الوضع الداكن (Dark Mode) — الأساسي
  // ============================================================
  static Color background = const Color(0xFF021612);
  static Color cardBackground = const Color(0xFF0A2E26);
  static Color emerald = const Color(0xFF03251D);
  static Color emeraldLight = const Color(0xFF0A4D3A);
  
  static const Color gold = Color(0xFFB8860B); // Premium Dark Gold
  static const Color goldAccent = Color(0xFFD4AF37); // Classic Gold
  static const Color cream = Color(0xFFFDF9F0); // Mushaf Page Background

  // ألوان الواجهة الداكنة
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);

  // زجاجي (Glassmorphism)
  static Color glassBackground = Colors.white.withValues(alpha: 0.1);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);
  static Color glassBackgroundDark = Colors.black.withValues(alpha: 0.4);

  // Legacy support
  static Color get divider => emeraldLight;

  // ============================================================
  //  الوضع الفاتح (Light Mode)
  // ============================================================
  
  // خلفية فاتحة دافئة
  static Color lightBackground = const Color(0xFFF5F0E8);
  static Color lightCardBackground = const Color(0xFFFFFFFF);
  static Color lightEmerald = const Color(0xFF0D6B4F);
  static Color lightEmeraldSurface = const Color(0xFFE8F5F0);
  
  static Color lightTextPrimary = const Color(0xFF1A1A1A);
  static Color lightTextSecondary = const Color(0xFF4A4A4A);
  static Color lightTextMuted = const Color(0xFF8A8A8A);

  // زجاجي فاتح
  static Color lightGlassBackground = Colors.white.withValues(alpha: 0.7);
  static Color lightGlassBorder = const Color(0xFFD0D0D0);

  // ============================================================
  //  تغيير الألوان بناءً على السمة (Theme switching)
  // ============================================================
  static void applyColorTheme(String colorTheme) {
    if (colorTheme == 'burgundy') {
      // Dark
      background = const Color(0xFF1F0E12); // Deep Burgundy Background
      cardBackground = const Color(0xFF2D161A);
      emerald = const Color(0xFF2D161A); // Used interchangeably in legacy
      emeraldLight = const Color(0xFF4A252B);
      
      // Light
      lightBackground = const Color(0xFFFFF5F5);
      lightEmerald = const Color(0xFF7D1B2D);
      lightEmeraldSurface = const Color(0xFFFDE8EA);
    } else if (colorTheme == 'blue') {
      // Dark
      background = const Color(0xFF0A1526); // Deep Navy Navy
      cardBackground = const Color(0xFF10203D);
      emerald = const Color(0xFF10203D);
      emeraldLight = const Color(0xFF1E3A68);
      
      // Light
      lightBackground = const Color(0xFFF0F5FA);
      lightEmerald = const Color(0xFF104A8E);
      lightEmeraldSurface = const Color(0xFFE6F0FA);
    } else if (colorTheme == 'monochrome') {
      // Dark
      background = const Color(0xFF121212); // Deep Charcoal
      cardBackground = const Color(0xFF1E1E1E);
      emerald = const Color(0xFF1A1A1A);
      emeraldLight = const Color(0xFF2C2C2C);
      
      // Light
      lightBackground = const Color(0xFFF8F8F8);
      lightEmerald = const Color(0xFF404040);
      lightEmeraldSurface = const Color(0xFFEEEEEE);
    } else if (colorTheme == 'gold') {
      // Dark
      background = const Color(0xFF141005); // Deep Dark Gold/Brown Background
      cardBackground = const Color(0xFF261D0B);
      emerald = const Color(0xFF33270F); 
      emeraldLight = const Color(0xFF594517);
      
      // Light
      lightBackground = const Color(0xFFFAF6EB);
      lightEmerald = const Color(0xFF8F6E20);
      lightEmeraldSurface = const Color(0xFFF5EEDB);
    } else {
      // Default: Emerald (الزمردي الأصلي)
      // Dark
      background = const Color(0xFF021612);
      cardBackground = const Color(0xFF0A2E26);
      emerald = const Color(0xFF03251D);
      emeraldLight = const Color(0xFF0A4D3A);
      
      // Light
      lightBackground = const Color(0xFFF5F0E8);
      lightEmerald = const Color(0xFF0D6B4F);
      lightEmeraldSurface = const Color(0xFFE8F5F0);
    }
  }

  // ============================================================
  //  Helper — يرجع اللون المناسب حسب السياق
  // ============================================================

  /// يعطيك اللون المناسب بناءً على سطوع الثيم
  static Color adaptive(BuildContext context, Color dark, Color light) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// اختصارات سريعة
  static Color bg(BuildContext context) =>
      adaptive(context, background, lightBackground);

  static Color card(BuildContext context) =>
      adaptive(context, cardBackground, lightCardBackground);

  static Color text(BuildContext context) =>
      adaptive(context, textPrimary, lightTextPrimary);

  static Color textSec(BuildContext context) =>
      adaptive(context, textSecondary, lightTextSecondary);

  static Color textMut(BuildContext context) =>
      adaptive(context, textMuted, lightTextMuted);

  static Color emr(BuildContext context) =>
      adaptive(context, emerald, lightEmerald);

  static Color emrSurface(BuildContext context) =>
      adaptive(context, cardBackground, lightEmeraldSurface);

  static Color glass(BuildContext context) =>
      adaptive(context, glassBackground, lightGlassBackground);

  static Color glassBrd(BuildContext context) =>
      adaptive(context, glassBorder, lightGlassBorder);
}
