import 'package:shared_preferences/shared_preferences.dart';

/// خدمة إدارة الرواية (حفص، ورش، إلخ)
/// Service to manage the reading (Hafs, Warsh, etc.)
class ReadingService {
  static const String _key = 'selected_qiraah';
  
  // القيم الممكنة - Possible values
  static const String hafs = 'حفص';
  static const String warsh = 'ورش';

  /// جلب الرواية المختارة حالياً (حفص افتراضياً)
  /// Get the currently selected reading (Hafs by default)
  static Future<String> getSelectedReading() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? hafs;
  }

  /// حفظ الرواية المختارة
  /// Save the selected reading
  static Future<void> setSelectedReading(String reading) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, reading);
  }

  /// التحقق مما إذا كانت الرواية هي ورش
  /// Check if the reading is Warsh
  static Future<bool> isWarsh() async {
    final reading = await getSelectedReading();
    return reading == warsh;
  }
}
