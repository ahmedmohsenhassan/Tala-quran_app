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
    return prefs.getString(_fontKey) ?? fontAmiri; // افتراضي: أميري
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
}
