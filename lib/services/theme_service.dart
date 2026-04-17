import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة المظهر — Theme Management Service
/// يحفظ ويسترجع تفضيلات المظهر (داكن/فاتح/تلقائي)
class ThemeService {
  static const String _key = 'app_theme_mode';

  static const String _colorKey = 'app_theme_color';
  static const String _fontKey = 'app_theme_font';
  static const String _fontSizeKey = 'app_theme_font_size';
  static const String _mushafThemeKey = 'app_mushaf_theme';

  /// القيم المتاحة للمظهر (Mode): 'dark', 'light', 'system'
  static const String dark = 'dark';
  static const String light = 'light';
  static const String system = 'system';

  /// القيم المتاحة للألوان (Color): 'emerald', 'burgundy', 'blue', 'monochrome', 'gold'
  static const String colorEmerald = 'emerald';
  static const String colorBurgundy = 'burgundy';
  static const String colorBlue = 'blue';
  static const String colorMonochrome = 'monochrome';
  static const String colorGold = 'gold';

  /// القيم المتاحة للخطوط (Font): 'Amiri', 'Uthmanic', 'Naskh', 'IndoPak'
  static const String fontAmiri = 'Amiri';
  static const String fontUthmanic = 'Uthmanic';
  static const String fontNaskh = 'Naskh';
  static const String fontIndopak = 'IndoPak';

  /// ثيمات المصحف (Mushaf Themes)
  static const String mushafClassic = 'classic'; // Green (default)
  static const String mushafPremium = 'premium'; // Gold ornate
  static const String mushafDark = 'dark_green'; // Dimmed comfort

  static const String _quranFontSizeKey = 'app_quran_font_size';
  static const String _translationFontSizeKey = 'app_translation_font_size';
  static const String _mushafEditionKey = 'app_mushaf_edition';

  /// Editions
  static const String editionMadina1405 = 'madina_1405';
  static const String editionMadina1422 = 'madina_1422';
  static const String editionWarsh = 'warsh_1428';

  /// استرجاع حجم الخط القرآني (Default: 24.0)
  static Future<double> getQuranFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_quranFontSizeKey) ?? 24.0;
  }

  static Future<void> setQuranFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_quranFontSizeKey, size);
  }

  /// استرجاع حجم خط الترجمة (Default: 16.0)
  static Future<double> getTranslationFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_translationFontSizeKey) ?? 16.0;
  }

  static Future<void> setTranslationFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_translationFontSizeKey, size);
  }

  /// استرجاع طبعة المصحف
  static Future<String> getMushafEdition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mushafEditionKey) ?? editionMadina1405;
  }

  static Future<void> setMushafEdition(String edition) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mushafEditionKey, edition);
  }

  /// استرجاع المظهر المحفوظ
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? dark; // افتراضي: داكن
  }

  /// حفظ المظهر المختار
  static Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode);
  }

  /// استرجاع اللون المختار
  static Future<String> getThemeColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_colorKey) ?? colorEmerald; // افتراضي: زمردي
  }

  /// حفظ اللون المختار
  static Future<void> setThemeColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, color);
  }

  /// استرجاع الخط المختار
  static Future<String> getThemeFont() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontKey) ?? fontUthmanic; // افتراضي: عثماني
  }

  /// حفظ الخط المختار
  static Future<void> setThemeFont(String font) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font);
  }

  /// استرجاع حجم الخط المختار (مضاعف)
  static Future<double> getFontSizeMultiplier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 1.0;
  }

  /// حفظ مضاعف حجم الخط
  static Future<void> setFontSizeMultiplier(double multiplier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, multiplier);
  }

  /// استرجاع ثيم المصحف المختار
  static Future<String> getMushafTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mushafThemeKey) ?? mushafClassic;
  }

  /// حفظ ثيم المصحف المختار
  static Future<void> setMushafTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mushafThemeKey, theme);
  }

  // --- Mushaf Color Helpers ---

  static Color getMushafDeepGreen(String theme) {
    if (theme == mushafPremium) return const Color(0xFF031E17);
    if (theme == mushafDark) return const Color(0xFF0C1D18);
    return const Color(0xFF0F291E); // Classic
  }

  static Color getMushafRichGold(String theme) {
    if (theme == mushafPremium) return const Color(0xFFEBC351); // Brighter gold
    return const Color(0xFFD4A947); // Standard gold
  }

  static Color getMushafParchment(String theme) {
    if (theme == mushafPremium) return const Color(0xFFFDF6E3); 
    if (theme == mushafDark) return const Color(0xFFE8E1CC);
    return const Color(0xFFF4ECD8); // Classic
  }

  static Color getMushafParchmentDark(String theme) {
    return const Color(0xFFE2D9C2);
  }
}
