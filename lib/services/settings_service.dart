import 'package:shared_preferences/shared_preferences.dart';
import 'package:tala_quran_app/models/reciter_model.dart';
import 'package:tala_quran_app/services/audio_url_service.dart';

enum ReadingMethod { pages, scroll }
enum LastPageAction { resume, ask, showList }

class SettingsService {
  static const String _keepScreenOnKey = 'settings_keep_screen_on';
  static const String _readingMethodKey = 'settings_reading_method';
  static const String _lastPageActionKey = 'settings_last_page_action';
  static const String _showDecorationsKey = 'settings_show_decorations';
  static const String _updateNotificationsKey = 'settings_update_notifications';
  static const String _languageKey = 'settings_language';
  static const String _scrollSpeedKey = 'settings_scroll_speed';
  static const String _showProgressInNotificationsKey = 'settings_show_progress_in_notifications';
  static const String _showTajweedKey = 'settings_show_tajweed'; // 🎨 Phase 103
  static const String _selectedReciterIdKey = 'settings_selected_reciter_id';

  /// إبقاء الشاشة مضاءة — Keep screen on (Default: true)
  static Future<bool> getKeepScreenOn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepScreenOnKey) ?? true;
  }

  static Future<void> setKeepScreenOn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepScreenOnKey, value);
  }

  /// طريقة التصفح — Reading Method (Default: pages)
  static Future<ReadingMethod> getReadingMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_readingMethodKey) ?? 0;
    return ReadingMethod.values[index];
  }

  static Future<void> setReadingMethod(ReadingMethod method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_readingMethodKey, method.index);
  }

  /// آخر موضع للقراءة — Last Page Action (Default: resume)
  static Future<LastPageAction> getLastPageAction() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_lastPageActionKey) ?? 0;
    return LastPageAction.values[index];
  }

  static Future<void> setLastPageAction(LastPageAction action) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPageActionKey, action.index);
  }

  /// إظهار الخلفيات الزخرفية — Show Decorations (Default: true)
  static Future<bool> getShowDecorations() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showDecorationsKey) ?? true;
  }

  static Future<void> setShowDecorations(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDecorationsKey, value);
  }

  /// تنبيه التحديثات — Update Notifications (Default: true)
  static Future<bool> getUpdateNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_updateNotificationsKey) ?? true;
  }

  static Future<void> setUpdateNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_updateNotificationsKey, value);
  }

  /// اللغة — Language (Default: ar)
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'ar';
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, lang);
  }

  /// إعادة تعيين كافة الإعدادات — Reset all settings
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keepScreenOnKey);
    await prefs.remove(_readingMethodKey);
    await prefs.remove(_lastPageActionKey);
    await prefs.remove(_showDecorationsKey);
    await prefs.remove(_updateNotificationsKey);
    await prefs.remove(_languageKey);
    await prefs.remove(_scrollSpeedKey);
    await prefs.remove(_showProgressInNotificationsKey);
  }

  /// سرعة التمرير التلقائي — Scroll Speed (Default: 1.0)
  static Future<double> getScrollSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_scrollSpeedKey) ?? 1.0;
  }

  static Future<void> setScrollSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scrollSpeedKey, value);
  }

  /// إظهار التقدم في الإشعارات — Show Progress in Notifications (Default: true)
  static Future<bool> getShowProgressInNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showProgressInNotificationsKey) ?? true;
  }

  static Future<void> setShowProgressInNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showProgressInNotificationsKey, value);
  }

  /// إظهار التجويد — Show Tajweed (Default: false)
  static Future<bool> getShowTajweed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showTajweedKey) ?? false;
  }

  static Future<void> setShowTajweed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showTajweedKey, value);
  }

  /// إظهار منزلق الصفحات — Show Page Slider (Default: false)
  static const String _showPageSliderKey = 'settings_show_page_slider';

  static Future<bool> getShowPageSlider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showPageSliderKey) ?? false;
  }

  static Future<void> setShowPageSlider(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPageSliderKey, value);
  }

  /// القارئ المفضل — Selected Reciter (Default: al_afasy)
  static Future<Reciter> getSelectedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedReciterIdKey) ?? 'al_afasy';
    return AudioUrlService.getReciterById(id);
  }

  static Future<void> setSelectedReciter(String reciterId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedReciterIdKey, reciterId);
  }
}
