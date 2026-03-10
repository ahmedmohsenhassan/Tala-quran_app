import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// خدمة إحصائيات القراءة — Reading Statistics Service
class ReadingStatsService {
  static const String _dailyStatsKey = 'stats_daily';
  static const String _totalPagesKey = 'stats_total_pages';
  static const String _totalSessionsKey = 'stats_total_sessions';

  /// تسجيل جلسة قراءة — Record a reading session
  static Future<void> recordSession({int pages = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _today();

    // تحديث إحصائيات اليوم — Update today's stats
    final dailyStr = prefs.getString(_dailyStatsKey);
    Map<String, dynamic> daily = {};
    if (dailyStr != null) {
      daily = jsonDecode(dailyStr) as Map<String, dynamic>;
    }
    daily[todayStr] = (daily[todayStr] ?? 0) + pages;

    // الاحتفاظ بآخر 30 يوم فقط — Keep only last 30 days
    if (daily.length > 30) {
      final keys = daily.keys.toList()..sort();
      for (int i = 0; i < daily.length - 30; i++) {
        daily.remove(keys[i]);
      }
    }

    await prefs.setString(_dailyStatsKey, jsonEncode(daily));
    await prefs.setInt(
        _totalPagesKey, (prefs.getInt(_totalPagesKey) ?? 0) + pages);
    await prefs.setInt(
        _totalSessionsKey, (prefs.getInt(_totalSessionsKey) ?? 0) + 1);
  }

  /// الحصول على جميع الإحصائيات — Get all stats
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyStr = prefs.getString(_dailyStatsKey);
    Map<String, dynamic> daily = {};
    if (dailyStr != null) {
      daily = jsonDecode(dailyStr) as Map<String, dynamic>;
    }

    final todayStr = _today();
    final int todayPages = daily[todayStr] ?? 0;
    final int totalPages = prefs.getInt(_totalPagesKey) ?? 0;
    final int totalSessions = prefs.getInt(_totalSessionsKey) ?? 0;

    // إحصائيات الأسبوع — Weekly stats
    final weekData = _getWeekData(daily);
    final weekTotal = weekData.fold<int>(0, (sum, v) => sum + v);
    final weekAvg = weekData.isEmpty ? 0 : (weekTotal / 7).round();

    return {
      'todayPages': todayPages,
      'totalPages': totalPages,
      'totalSessions': totalSessions,
      'weekData': weekData,
      'weekTotal': weekTotal,
      'weekAverage': weekAvg,
      'dailyGoalProgress': (todayPages / 5).clamp(0.0, 1.0), // هدف 5 صفحات
    };
  }

  /// بيانات الأسبوع — Get this week's data
  static List<int> _getWeekData(Map<String, dynamic> daily) {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final key = _dateToStr(date);
      return (daily[key] ?? 0) as int;
    });
  }

  static String _today() => _dateToStr(DateTime.now());

  static String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
