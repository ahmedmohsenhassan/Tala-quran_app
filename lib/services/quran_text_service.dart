import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

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
  Future<String> getTafseer(int surah, int ayah) async {
    try {
      // استخدام تفسير الجلالين (رقم 16 في API quran.com)
      // Using Tafseer Al-Jalalayn (ID 16)
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/tafsirs/16',
        queryParameters: {'verse_key': '$surah:$ayah'},
      );

      if (response.statusCode == 200) {
        final List tafsirs = response.data['tafsirs'];
        if (tafsirs.isNotEmpty) {
          return tafsirs[0]['text'] ?? "لا يوجد تفسير متاح.";
        }
      }
      return "تعذر جلب التفسير.";
    } catch (e) {
      return "خطأ في الاتصال: $e";
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
