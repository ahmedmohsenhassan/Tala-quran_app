import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎙️ خدمة مزامنة التلاوة — Recitation Sync Service
/// مسؤول عن جلب مواقيت الكلمات (Timestamps) للتظليل اللحظي
class RecitationSyncService {
  static final RecitationSyncService _instance = RecitationSyncService._internal();
  factory RecitationSyncService() => _instance;
  RecitationSyncService._internal();

  final Dio _dio = Dio();

  /// جلب مواقيت الكلمات لآية معينة — Fetch Word Timestamps for a Verse
  /// [reciterId]: معرف القاري (مثلاً 7 للعفاسي)
  /// [verseKey]: مفتاح الآية (مثلاً "1:1")
  Future<List<Map<String, dynamic>>> getVerseTimestamps(int reciterId, String verseKey) async {
    final prefs = await SharedPreferences.getInstance();
    const String prefix = 'timestamps_';
    final cacheKey = '$prefix${reciterId}_$verseKey';

    // 1. محاولة الجلب من التخزين المحلي (Cache)
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    // 2. الجلب من API إذا لم تكن موجودة
    try {
      final response = await _dio.get(
        "https://api.quran.com/api/v4/recitations/$reciterId/by_ayah/$verseKey",
        queryParameters: {'fields': 'segments'},
      );

      if (response.statusCode == 200) {
        final List audioFiles = response.data['audio_files'];
        if (audioFiles.isNotEmpty && audioFiles.first['segments'] != null) {
          final List timestamps = audioFiles.first['segments'];
          
          final formatted = timestamps.map((s) {
            return {
              'word_index': s[0] + 1, // Word position (1-based for UI matching)
              'start': s[2],          // Milliseconds
              'end': s[3],            // Milliseconds
            };
          }).toList();

          // 3. حفظ في الكاش
          await prefs.setString(cacheKey, json.encode(formatted));
          return List<Map<String, dynamic>>.from(formatted);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching timestamps for $verseKey: $e');
    }
    return [];
  }

  /// العثور على الكلمة النشطة بناءً على الوقت الحالي — Find Active Word by Time
  /// [currentTimeMs]: الوقت الحالي بالملي ثانية
  /// [segments]: قائمة المناطق الزمنية للكلمات
  int? findActiveWordIndex(int currentTimeMs, List<Map<String, dynamic>> segments) {
    if (segments.isEmpty) return null;
    
    for (var segment in segments) {
      if (currentTimeMs >= segment['start'] && currentTimeMs < segment['end']) {
        return segment['word_index'];
      }
    }
    return null;
  }
}
