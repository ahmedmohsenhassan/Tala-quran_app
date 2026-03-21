import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌟 خدمة آية اليوم — Daily Verse Service
/// Selects a deterministic "verse of the day" based on the current date
class DailyVerseService {
  static const String _cachedVerseKey = 'daily_verse_data';
  static const String _cachedDateKey = 'daily_verse_date';

  /// الحصول على آية اليوم — Get today's verse
  static Future<Map<String, dynamic>> getTodayVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _today();

    // Check if we already have today's verse cached
    final cachedDate = prefs.getString(_cachedDateKey);
    if (cachedDate == todayStr) {
      final cachedVerse = prefs.getString(_cachedVerseKey);
      if (cachedVerse != null) {
        return jsonDecode(cachedVerse);
      }
    }

    // Load verses from JSON asset
    try {
      final jsonStr = await rootBundle.loadString('assets/data/quran_notification_verses.json');
      final data = jsonDecode(jsonStr);
      final dailyVerses = data['categories']['daily_verse']['verses'] as List;

      // Use day-of-year as a seed for deterministic daily selection
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final index = dayOfYear % dailyVerses.length;
      final verse = Map<String, dynamic>.from(dailyVerses[index]);

      // Cache it
      await prefs.setString(_cachedDateKey, todayStr);
      await prefs.setString(_cachedVerseKey, jsonEncode(verse));

      return verse;
    } catch (e) {
      // Fallback verse
      return {
        'title': 'آية اليوم ✨',
        'body': '﴿أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ﴾ — الرعد:28',
        'surah': 13,
        'ayah': 28,
      };
    }
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
