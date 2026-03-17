import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tafseer_service.dart';

/// خدمة جلب نص القرآن الكريم
/// Service to fetch Quranic text from API or local JSON assets
class QuranTextService {
  static final QuranTextService _instance = QuranTextService._internal();
  factory QuranTextService() => _instance;
  QuranTextService._internal();

  final Dio _dio = Dio();

  /// البحث عن آيات تحتوي على نص معين
  /// Search for ayahs containing specific text
  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/search',
        queryParameters: {'q': query, 'language': 'ar', 'size': 20},
      );

      if (response.statusCode == 200) {
        final List results = response.data['search']['results'];
        return results.map((r) {
          return {
            "surahNumber": r['verse_key'].split(':')[0],
            "verseNumber": r['verse_key'].split(':')[1],
            "text": r['text'],
            "verseKey": r['verse_key'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب تفسير آية معينة
  /// Fetch Tafseer for a specific verse
  Future<Map<String, String>> getTafseer(int surah, int ayah) async {
    try {
      // قراءة التفسير المفضل للمستخدم (الافتراضي 16 الجلالين)
      final tafseerId = await TafseerService.getTafseerId();
      final tafseerName = TafseerService.availableTafseers[tafseerId] ?? 'التفسير';

      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/tafsirs/$tafseerId',
        queryParameters: {'verse_key': '$surah:$ayah'},
      );

      if (response.statusCode == 200) {
        final List tafsirs = response.data['tafsirs'];
        if (tafsirs.isNotEmpty) {
          return {
            'text': tafsirs[0]['text'] ?? "لا يوجد تفسير متاح.",
            'name': tafseerName,
          };
        }
      }
      return {'text': "تعذر جلب التفسير.", 'name': tafseerName};
    } catch (e) {
      return {'text': "خطأ في الاتصال: $e", 'name': 'خطأ'};
    }
  }

  /// جلب الترجمة لآية معينة (مع التخزين المؤقت - Offline Cache)
  /// Fetch Translation for a specific verse with caching mechanism
  Future<String> getTranslation(int surah, int ayah, int translationId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'translation_${translationId}_${surah}_$ayah';

    // 1. محاولة جلبها من الكاش (Offline)
    final cachedTranslation = prefs.getString(cacheKey);
    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    // 2. إذا لم تكن موجودة، جلبها من API
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/translations/$translationId',
        queryParameters: {'verse_key': '$surah:$ayah'},
      );

      if (response.statusCode == 200) {
        final List translations = response.data['translations'];
        if (translations.isNotEmpty) {
          // تنظيف نص الترجمة من أي وسوم HTML قبل الحفظ
          String text = translations[0]['text'] ?? "";
          text = text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '');
          
          // 3. حفظها في الكاش للمرة القادمة
          await prefs.setString(cacheKey, text);
          return text;
        }
      }
      return "";
    } catch (e) {
      return ""; // إرجاع نص فارغ في حالة الخطأ لعدم إفساد تجربة القراءة
    }
  }

  /// جلب بيانات السورة بالكامل (آيات نصية)
  /// Fetch complete Surah data (Uthmani text)
  Future<Map<String, dynamic>> getSurahDetail(int surahNumber) async {
    try {
      // محاولة جلب البيانات من API حقيقي أولاً لضمان الدقة
      // Try fetching from real API first for accuracy
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/verses/uthmani',
        queryParameters: {'chapter_number': surahNumber},
      );

      if (response.statusCode == 200) {
        final List verses = response.data['verses'];
        return {
          "surahNumber": surahNumber,
          "ayahs": verses.map((v) {
            // Parse verse number from verse_key (e.g., "1:1" -> 1)
            int num = 1;
            try {
              if (v['verse_key'] != null) {
                num = int.parse(v['verse_key'].split(':')[1]);
              } else {
                num = v['id'] ?? 1;
              }
            } catch (_) {
              num = v['id'] ?? 1;
            }

            return {
              "number": num,
              "text": v['text_uthmani'] ?? "",
            };
          }).toList(),
        };
      }
      throw Exception('API failed');
    } catch (e) {
      // Fallback to local assets if offline or API fails
      try {
        String fileName = _getFileName(surahNumber);
        final String localData =
            await rootBundle.loadString('assets/surahs/$fileName.json');
        return json.decode(localData);
      } catch (err) {
        return {
          "error": "فشل تحميل البيانات",
          "ayahs": [
            {"number": 1, "text": "عذراً، يرجى التحقق من الاتصال بالإنترنت."}
          ]
        };
      }
    }
  }

  /// جلب آيات صفحة معينة مع بيانات الكلمات والأسطر (للدقة القصوى)
  /// Fetch verses for a specific page with word-level data and line numbers
  Future<List<Map<String, dynamic>>> getVersesByPage(int pageNumber) async {
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/verses/uthmani',
        queryParameters: {
          'page_number': pageNumber,
          'fields': 'text_uthmani,verse_key,line_number,page_number',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['verses']);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching page verses: $e");
      return [];
    }
  }

  /// جلب بيانات الكلمات لصفحة معينة (للتظليل كلمة بكلمة)
  /// Fetch word-level data for a specific page (for Word-by-Word highlighting)
  Future<List<Map<String, dynamic>>> getPageWords(int pageNumber) async {
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/verses/by_page/$pageNumber',
        queryParameters: {
          'words': 'true',
          'word_fields': 'text_uthmani,line_number,location',
        },
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['verses']);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching page words: $e");
      return [];
    }
  }

  String _getFileName(int number) {
    final names = {
      1: "Al-Fatihah",
      2: "Al-Baqarah",
      3: "Aal-i-Imraan",
      4: "An-Nisaa",
      5: "Al-Maaida",
      6: "Al-An'aam",
      7: "Al-A'raaf",
      8: "Al-Anfaal",
      9: "At-Tawba",
      19: "Maryam",
      36: "Yaseen",
      67: "Al-Mulk",
    };
    return names[number] ?? "Surah_$number";
  }
}
