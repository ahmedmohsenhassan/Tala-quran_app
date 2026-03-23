import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'tafseer_service.dart';
import 'quran_database_service.dart';

/// خدمة جلب نص القرآن الكريم — 100% Offline-First
/// Service to fetch Quranic text from local SQLite DB
/// API is used ONLY for Tafseer/Translation (supplementary)
class QuranTextService {
  static final QuranTextService _instance = QuranTextService._internal();
  factory QuranTextService() => _instance;
  QuranTextService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  final QuranDatabaseService _quranDb = QuranDatabaseService();

  // Cache for local directory path
  static String? _localDirPath;

  static Future<String> _getLocalPath() async {
    if (_localDirPath != null) return _localDirPath!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _localDirPath = dir.path;
      return _localDirPath!;
    } catch (_) {
      return '';
    }
  }

  // ======================================================================
  //  🔍 البحث — Search (100% Offline via SQLite)
  // ======================================================================

  /// البحث عن آيات تحتوي على نص معين
  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    try {
      return await _quranDb.searchVerses(query);
    } catch (e) {
      debugPrint('❌ [QuranTextService] Search Error: $e');
      return [];
    }
  }

  // ======================================================================
  //  📖 جلب بيانات السورة — Surah Data (100% Offline)
  // ======================================================================

  /// جلب بيانات السورة بالكامل (آيات نصية) — من SQLite المحلي
  Future<Map<String, dynamic>> getSurahDetail(int surahNumber) async {
    try {
      // 1. SQLite أولاً (سريع ومحلي)
      final verses = await _quranDb.getVersesBySurah(surahNumber);
      if (verses.isNotEmpty) {
        return {
          "surahNumber": surahNumber,
          "ayahs": verses.map((v) => {
            "number": v['ayah'],
            "text": v['text'],
          }).toList(),
        };
      }
    } catch (e) {
      debugPrint('⚠️ [QuranTextService] SQLite failed: $e');
    }

    // 2. Fallback to local JSON assets
    try {
      final fileName = _getSurahFileName(surahNumber);
      final String localData = await rootBundle.loadString('assets/surahs/$fileName.json');
      return json.decode(localData);
    } catch (err) {
      debugPrint('❌ [QuranTextService] JSON Fallback also failed: $err');
      return {
        "error": "فشل تحميل البيانات",
        "ayahs": [
          {"number": 1, "text": "عذراً، تعذر تحميل بيانات السورة. جرب إعادة تشغيل التطبيق."}
        ]
      };
    }
  }

  // ======================================================================
  //  📄 جلب آيات الصفحة — Page Verses (100% Offline)
  // ======================================================================

  /// جلب آيات صفحة معينة
  Future<List<Map<String, dynamic>>> getVersesByPage(int pageNumber) async {
    // 1. SQLite أولاً
    try {
      final verses = await _quranDb.getVersesByPage(pageNumber);
      if (verses.isNotEmpty) return verses;
    } catch (_) {}

    // 2. Local Assets fallback (bundled)
    try {
      final String localData = await rootBundle.loadString('assets/mushaf/data/verses_p$pageNumber.json');
      final decoded = json.decode(localData);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (_) {}

    // 3. Local STORAGE (Downloaded)
    try {
      final localPath = await _getLocalPath();
      final file = File('$localPath/mushaf/$pageNumber/verses_p$pageNumber.json');
      if (await file.exists()) {
        final String content = await file.readAsString();
        return List<Map<String, dynamic>>.from(json.decode(content));
      }
    } catch (_) {}

    return [];
  }

  /// جلب بيانات الكلمات لصفحة معينة (للتظليل كلمة بكلمة)
  Future<List<Map<String, dynamic>>> getPageWords(int pageNumber) async {
    // 1. Local Assets (Bundled)
    try {
      final String localData = await rootBundle.loadString('assets/mushaf/data/words_p$pageNumber.json');
      final decoded = json.decode(localData);
      return List<Map<String, dynamic>>.from(decoded);
    } catch (_) {}

    // 2. Local STORAGE (Downloaded)
    try {
      final localPath = await _getLocalPath();
      final file = File('$localPath/mushaf/$pageNumber/words_p$pageNumber.json');
      if (await file.exists()) {
        final String content = await file.readAsString();
        return List<Map<String, dynamic>>.from(json.decode(content));
      }
    } catch (_) {}

    return [];
  }

  // ======================================================================
  //  📚 التفسير — Tafseer (API with Offline Cache)
  // ======================================================================

  /// جلب تفسير آية معينة (مع تخزين محلي دائم)
  Future<Map<String, String>> getTafseer(int surah, int ayah) async {
    try {
      final tafseerId = await TafseerService.getTafseerId();
      final tafseerName = TafseerService.availableTafseers[tafseerId] ?? 'التفسير';

      // 1. فحص الكاش أولاً (Offline)
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'tafseer_${tafseerId}_${surah}_$ayah';
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return {'text': cached, 'name': tafseerName};
      }

      // 2. جلب من API وحفظ محلياً
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/tafsirs/$tafseerId',
        queryParameters: {'verse_key': '$surah:$ayah'},
      );

      if (response.statusCode == 200) {
        final List tafsirs = response.data['tafsirs'];
        if (tafsirs.isNotEmpty) {
          final text = tafsirs[0]['text'] ?? "لا يوجد تفسير متاح.";
          // حفظ في الكاش للاستخدام بدون إنترنت
          await prefs.setString(cacheKey, text);
          return {'text': text, 'name': tafseerName};
        }
      }
      return {'text': "تعذر جلب التفسير. تأكد من الاتصال بالإنترنت.", 'name': tafseerName};
    } catch (e) {
      final tafseerId = await TafseerService.getTafseerId();
      final tafseerName = TafseerService.availableTafseers[tafseerId] ?? 'التفسير';
      return {'text': "التفسير غير متاح حالياً (بدون إنترنت).", 'name': tafseerName};
    }
  }

  // ======================================================================
  //  🌍 الترجمة — Translation (API with Offline Cache)
  // ======================================================================

  /// جلب الترجمة لآية معينة (مع التخزين المؤقت الدائم)
  Future<String> getTranslation(int surah, int ayah, int translationId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'translation_${translationId}_${surah}_$ayah';

    // 1. الكاش المحلي أولاً (Offline)
    final cachedTranslation = prefs.getString(cacheKey);
    if (cachedTranslation != null) {
      return cachedTranslation;
    }

    // 2. جلب من API
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/translations/$translationId',
        queryParameters: {'verse_key': '$surah:$ayah'},
      );

      if (response.statusCode == 200) {
        final List translations = response.data['translations'];
        if (translations.isNotEmpty) {
          String text = translations[0]['text'] ?? "";
          text = text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '');
          await prefs.setString(cacheKey, text);
          return text;
        }
      }
      return "الترجمة غير متاحة حالياً.";
    } catch (e) {
      return ""; // إرجاع نص فارغ في حالة بدون إنترنت
    }
  }

  // ======================================================================
  //  🛠️ أدوات — Utilities
  // ======================================================================

  /// Map surah number to its JSON filename
  String _getSurahFileName(int number) {
    return QuranDatabaseService.surahFiles[number - 1];
  }
}
