import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// خدمة إحصائيات القراءة — Reading Statistics Service
class ReadingStatsService {
  static const String _dailyStatsKey = 'stats_daily';
  static const String _totalPagesKey = 'stats_total_pages';
  static const String _totalSessionsKey = 'stats_total_sessions';
  static const String _dailyGoalKey = 'stats_daily_goal';
  static const String _totalSessionMinutesKey = 'stats_total_session_minutes';

  /// الحصول على هدف القراءة اليومي (الافتراضي 5 صفحات)
  /// Get configurable daily reading goal (default 5 pages)
  static Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 5;
  }

  /// تعيين هدف القراءة اليومي
  /// Set daily reading goal
  static Future<void> setDailyGoal(int pages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, pages.clamp(1, 20));
  }

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

  /// تسجيل وقت الجلسة — Record session time
  static Future<void> recordSessionTime({required int minutes}) async {
    if (minutes <= 0) return; // Only record positive minutes
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _totalSessionMinutesKey, (prefs.getInt(_totalSessionMinutesKey) ?? 0) + minutes);
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
    final int totalSessionMinutes = prefs.getInt(_totalSessionMinutesKey) ?? 0; // Get total session minutes

    // إحصائيات الأسبوع — Weekly stats
    final weekData = _getWeekData(daily);
    final weekTotal = weekData.fold<int>(0, (sum, v) => sum + v);
    final weekAvg = weekData.isEmpty ? 0 : (weekTotal / 7).round();

    final int dailyGoal = prefs.getInt(_dailyGoalKey) ?? 5;

    return {
      'todayPages': todayPages,
      'totalPages': totalPages,
      'totalSessions': totalSessions,
      'totalSessionMinutes': totalSessionMinutes, // Add to returned stats
      'weekData': weekData,
      'weekTotal': weekTotal,
      'weekAverage': weekAvg,
      'dailyGoal': dailyGoal,
      'dailyGoalProgress': (todayPages / dailyGoal).clamp(0.0, 1.0),
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

  /// بيانات آخر 30 يوم للخريطة الحرارية — Get last 30 days data for heatmap
  static Future<Map<String, int>> getMonthData() async {
    final prefs = await SharedPreferences.getInstance();
    final dailyStr = prefs.getString(_dailyStatsKey);
    Map<String, dynamic> daily = {};
    if (dailyStr != null) {
      daily = jsonDecode(dailyStr) as Map<String, dynamic>;
    }

    final now = DateTime.now();
    final Map<String, int> monthData = {};
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 29 - i));
      final key = _dateToStr(date);
      monthData[key] = (daily[key] ?? 0) as int;
    }
    return monthData;
  }

  static String _dateToStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
