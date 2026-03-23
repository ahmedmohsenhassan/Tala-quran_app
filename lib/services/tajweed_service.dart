import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة جلب بيانات التجويد
/// Service to fetch Tajweed-encoded text
class TajweedService {
  static final TajweedService _instance = TajweedService._internal();
  factory TajweedService() => _instance;
  TajweedService._internal();

  final Dio _dio = Dio();

  /// جلب نص التجويد لآية معينة
  /// Fetch Tajweed text for a specific verse
  Future<String?> getTajweedText(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'tajweed_${surah}_$ayah';

    // 1. محاولة الجلب من الكاش
    final cached = prefs.getString(cacheKey);
    if (cached != null) return cached;

    // 2. الجلب من الـ API
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/verses/tajweed',
        queryParameters: {
          'verse_key': '$surah:$ayah',
        },
      );

      if (response.statusCode == 200) {
        final List verses = response.data['verses'];
        if (verses.isNotEmpty) {
          final tajweedText = verses[0]['text_tajweed'] as String?;
          if (tajweedText != null) {
            // حفظ في الكاش
            await prefs.setString(cacheKey, tajweedText);
            return tajweedText;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [TajweedService] Error fetching tajweed: $e');
      return null;
    }
  }

  /// جلب بيانات التجويد لصفحة كاملة (لتحسين الأداء)
  /// Fetch Tajweed data for a whole page to optimize performance
  Future<Map<String, String>> getPageTajweed(int pageNumber) async {
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/verses/tajweed',
        queryParameters: {
          'page_number': pageNumber,
        },
      );

      if (response.statusCode == 200) {
        final List verses = response.data['verses'];
        final Map<String, String> pageMap = {};
        for (var v in verses) {
          if (v['verse_key'] != null && v['text_tajweed'] != null) {
            pageMap[v['verse_key']] = v['text_tajweed'];
          }
        }
        return pageMap;
      }
      return {};
    } catch (e) {
      debugPrint('❌ [TajweedService] Error fetching page tajweed: $e');
      return {};
    }
  }
}
