import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تتبع الختمة — Khatma (Quran Completion) Tracker Service
class KhatmaService {
  static const String _activeKhatmaKey = 'khatma_active';
  static const String _completedCountKey = 'khatma_completed_count';
  static const String _historyKey = 'khatma_history';

  static const int totalPages = 604;

  /// إنشاء ختمة جديدة — Create a new Khatma
  static Future<void> createKhatma({required int targetDays}) async {
    final prefs = await SharedPreferences.getInstance();
    final khatma = {
      'startDate': DateTime.now().toIso8601String(),
      'targetDays': targetDays,
      'pagesRead': 0,
      'dailyTarget': (totalPages / targetDays).ceil(),
    };
    await prefs.setString(_activeKhatmaKey, jsonEncode(khatma));
  }

  /// تحديث تقدم الختمة — Update Khatma progress
  static Future<void> recordPage({int pages = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final khatmaStr = prefs.getString(_activeKhatmaKey);
    if (khatmaStr == null) return;

    final khatma = jsonDecode(khatmaStr) as Map<String, dynamic>;
    khatma['pagesRead'] = (khatma['pagesRead'] as int) + pages;

    // التحقق من إتمام الختمة — Check if completed
    if (khatma['pagesRead'] >= totalPages) {
      await _completeKhatma(prefs, khatma);
    } else {
      await prefs.setString(_activeKhatmaKey, jsonEncode(khatma));
    }
  }

  /// إتمام الختمة — Complete the Khatma
  static Future<void> _completeKhatma(
      SharedPreferences prefs, Map<String, dynamic> khatma) async {
    // زيادة العداد — Increment counter
    int completedCount = prefs.getInt(_completedCountKey) ?? 0;
    completedCount++;
    await prefs.setInt(_completedCountKey, completedCount);

    // حفظ في التاريخ — Save to history
    final historyStr = prefs.getString(_historyKey);
    List<Map<String, dynamic>> history = [];
    if (historyStr != null) {
      history = (jsonDecode(historyStr) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }
    history.add({
      'startDate': khatma['startDate'],
      'endDate': DateTime.now().toIso8601String(),
      'targetDays': khatma['targetDays'],
      'number': completedCount,
    });
    await prefs.setString(_historyKey, jsonEncode(history));

    // حذف الختمة النشطة — Remove active Khatma
    await prefs.remove(_activeKhatmaKey);
  }

  /// الحصول على بيانات الختمة النشطة — Get active Khatma data
  static Future<Map<String, dynamic>?> getActiveKhatma() async {
    final prefs = await SharedPreferences.getInstance();
    final khatmaStr = prefs.getString(_activeKhatmaKey);
    if (khatmaStr == null) return null;

    final khatma = jsonDecode(khatmaStr) as Map<String, dynamic>;
    final startDate = DateTime.parse(khatma['startDate']);
    final daysPassed = DateTime.now().difference(startDate).inDays;
    final int pagesRead = khatma['pagesRead'];
    final int dailyTarget = khatma['dailyTarget'];
    final int targetDays = khatma['targetDays'];
    final double progress = pagesRead / totalPages;

    // الصفحات المتبقية لليوم — Remaining pages for today
    final idealPagesForToday = (daysPassed + 1) * dailyTarget;
    final pagesNeededToday =
        (idealPagesForToday - pagesRead).clamp(0, totalPages - pagesRead);

    return {
      ...khatma,
      'daysPassed': daysPassed,
      'progress': progress,
      'pagesRemaining': totalPages - pagesRead,
      'pagesNeededToday': pagesNeededToday,
      'daysRemaining': (targetDays - daysPassed).clamp(0, targetDays),
      'isOnTrack': pagesRead >= (daysPassed * dailyTarget),
    };
  }

  /// عدد الختمات المكتملة — Get completed count
  static Future<int> getCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_completedCountKey) ?? 0;
  }

  /// تاريخ الختمات — Get history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString(_historyKey);
    if (historyStr == null) return [];
    return (jsonDecode(historyStr) as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
