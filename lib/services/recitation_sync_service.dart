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
  static const String _baseUrl = 'https://api.quran.com/api/v4/audio/reciters';

  /// جلب مواقيت الكلمات لآية معينة — Fetch Word Timestamps for a Verse
  /// [reciterId]: معرف القاري (مثلاً 7 للعفاسي)
  /// [verseKey]: مفتاح الآية (مثلاً "1:1")
  Future<List<Map<String, dynamic>>> getVerseTimestamps(int reciterId, String verseKey) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'timestamps_${reciterId}_$verseKey';

    // 1. محاولة الجلب من التخزين المحلي (Cache)
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(json.decode(cachedData));
    }

    // 2. الجلب من API إذا لم تكن موجودة
    try {
      final response = await _dio.get(
        '$_baseUrl/$reciterId/timestamp',
        queryParameters: {'verse_key': verseKey},
      );

      if (response.statusCode == 200) {
        final List timestamps = response.data['timestamp']['segments'];
        
        // تحويل البيانات لشكل مبسط (word_index, start_time, end_time)
        final formatted = timestamps.map((s) {
          return {
            'word_index': s[0], // Word position in inverse
            'start': s[1],      // Miliseconds
            'end': s[2],        // Miliseconds
          };
        }).toList();

        // 3. حفظ في الكاش
        await prefs.setString(cacheKey, json.encode(formatted));
        return List<Map<String, dynamic>>.from(formatted);
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
