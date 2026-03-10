import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تتبع المواظبة اليومية — Daily Streak Tracking Service
class StreakService {
  static const String _lastReadDateKey = 'streak_last_read_date';
  static const String _currentStreakKey = 'streak_current';
  static const String _longestStreakKey = 'streak_longest';
  static const String _totalDaysKey = 'streak_total_days';
  static const String _todayPagesKey = 'streak_today_pages';
  static const String _todayDateKey = 'streak_today_date';

  /// تسجيل قراءة اليوم — Record today's reading
  static Future<void> recordReading({int pages = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateToString(now);

    final lastDateStr = prefs.getString(_lastReadDateKey);
    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    int longestStreak = prefs.getInt(_longestStreakKey) ?? 0;
    int totalDays = prefs.getInt(_totalDaysKey) ?? 0;

    // تحديث عدد صفحات اليوم — Update today's page count
    final storedTodayDate = prefs.getString(_todayDateKey) ?? '';
    int todayPages = 0;
    if (storedTodayDate == todayStr) {
      todayPages = prefs.getInt(_todayPagesKey) ?? 0;
    }
    todayPages += pages;
    await prefs.setInt(_todayPagesKey, todayPages);
    await prefs.setString(_todayDateKey, todayStr);

    if (lastDateStr == todayStr) {
      // نفس اليوم، لا حاجة لتحديث الـ Streak
      return;
    }

    // تحديث الـ Streak
    if (lastDateStr != null) {
      final lastDate = _stringToDate(lastDateStr);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        // يوم متتالي — Consecutive day
        currentStreak++;
      } else if (difference > 1) {
        // فاتك يوم/أيام — Missed day(s), reset
        currentStreak = 1;
      }
    } else {
      // أول مرة — First time
      currentStreak = 1;
    }

    totalDays++;

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    await prefs.setString(_lastReadDateKey, todayStr);
    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setInt(_longestStreakKey, longestStreak);
    await prefs.setInt(_totalDaysKey, totalDays);
  }

  /// الحصول على بيانات الـ Streak — Get streak data
  static Future<Map<String, dynamic>> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _dateToString(now);

    int currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    final lastDateStr = prefs.getString(_lastReadDateKey);

    // التحقق من أن الـ Streak لا يزال نشطاً
    if (lastDateStr != null) {
      final lastDate = _stringToDate(lastDateStr);
      final difference = now.difference(lastDate).inDays;
      if (difference > 1) {
        currentStreak = 0; // الـ Streak انتهى
      }
    }

    // صفحات اليوم — Today's pages
    final storedTodayDate = prefs.getString(_todayDateKey) ?? '';
    int todayPages = 0;
    if (storedTodayDate == todayStr) {
      todayPages = prefs.getInt(_todayPagesKey) ?? 0;
    }

    // حالة أيام الأسبوع — Week days status
    final weekDays = _getWeekStatus(prefs, now);

    // حساب الإنجاز القادم — Next achievement
    final nextMilestone = _getNextMilestone(currentStreak);

    return {
      'currentStreak': currentStreak,
      'longestStreak': prefs.getInt(_longestStreakKey) ?? 0,
      'totalDays': prefs.getInt(_totalDaysKey) ?? 0,
      'todayPages': todayPages,
      'hasReadToday': lastDateStr == todayStr,
      'weekDays': weekDays,
      'nextMilestone': nextMilestone,
      'streakEmoji': _getStreakEmoji(currentStreak),
    };
  }

  /// حالة أيام الأسبوع — Week status
  static List<bool> _getWeekStatus(SharedPreferences prefs, DateTime now) {
    // بسيطة: نعرض إذا قرأ اليوم فقط
    final todayStr = _dateToString(now);
    final lastDateStr = prefs.getString(_lastReadDateKey);
    final hasReadToday = lastDateStr == todayStr;

    // 7 أيام: نرجع حالة تقريبية
    final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
    final weekday = now.weekday; // 1=Monday, 7=Sunday

    return List.generate(7, (i) {
      final dayIndex = i + 1;
      if (dayIndex < weekday) {
        // أيام سابقة: الـ Streak يغطيها؟
        return (weekday - dayIndex) < currentStreak;
      } else if (dayIndex == weekday) {
        return hasReadToday;
      } else {
        return false; // أيام مستقبلية
      }
    });
  }

  /// الإنجاز القادم — Next milestone
  static Map<String, dynamic> _getNextMilestone(int current) {
    final milestones = [
      {'days': 7, 'title': 'أسبوع مواظبة', 'emoji': '🌟'},
      {'days': 30, 'title': 'شهر مواظبة', 'emoji': '🏆'},
      {'days': 100, 'title': '100 يوم', 'emoji': '👑'},
      {'days': 365, 'title': 'سنة كاملة!', 'emoji': '🕌'},
    ];

    for (final m in milestones) {
      if (current < (m['days'] as int)) {
        return {
          'target': m['days'],
          'title': m['title'],
          'emoji': m['emoji'],
          'remaining': (m['days'] as int) - current,
        };
      }
    }

    return {
      'target': current + 100,
      'title': 'ما شاء الله!',
      'emoji': '🕌',
      'remaining': 100,
    };
  }

  /// إيموجي الـ Streak حسب العدد
  static String _getStreakEmoji(int streak) {
    if (streak >= 365) return '🕌';
    if (streak >= 100) return '👑';
    if (streak >= 30) return '🏆';
    if (streak >= 7) return '🌟';
    if (streak >= 3) return '🔥';
    return '✨';
  }

  // أدوات مساعدة — Helpers
  static String _dateToString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime _stringToDate(String str) {
    final parts = str.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}
