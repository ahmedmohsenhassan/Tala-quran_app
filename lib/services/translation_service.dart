import 'package:shared_preferences/shared_preferences.dart';

/// الخدمة المسؤولة عن إدارة تفضيلات الترجمة
class TranslationService {
  static const String _isTranslationEnabledKey = 'app_translation_enabled';
  static const String _translationLanguageKey = 'app_translation_language';

  // معرّفات الترجمة الافتراضية بناءً على api.quran.com
  // 20: English (Saheeh International)
  // 97: Urdu (Abul A'la Maududi)
  static const int langEnglish = 20;
  static const int langUrdu = 97;

  /// التحقق مما إذا كانت الترجمة مفعلة
  static Future<bool> isTranslationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isTranslationEnabledKey) ?? false;
  }

  /// تفعيل أو تعطيل الترجمة
  static Future<void> setTranslationEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTranslationEnabledKey, isEnabled);
  }

  /// الحصول على معرف لغة الترجمة الحالية
  static Future<int> getTranslationLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_translationLanguageKey) ?? langEnglish;
  }

  /// تغيير لغة الترجمة
  static Future<void> setTranslationLanguage(int langId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_translationLanguageKey, langId);
  }
}
