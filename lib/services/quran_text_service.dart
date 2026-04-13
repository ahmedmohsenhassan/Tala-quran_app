import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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
  //  📚 التفسير — Tafseer (SQLite-first with Auto-cache)
  // ======================================================================

  /// جلب تفسير آية معينة (أوفلاين من SQLite مع جلب تلقائي في الخلفية)
  Future<Map<String, String>> getTafseer(int surah, int ayah, {int? preferredTafseerId}) async {
    try {
      final tafseerId = preferredTafseerId ?? await TafseerService.getTafseerId();
      final tafseerName = TafseerService.availableTafseers[tafseerId] ?? 'التفسير';
      final identifier = 'tafseer-$tafseerId';

      // 1. محاولة الجلب من SQLite (الأولوية للأوفلاين)
      final localText = await _quranDb.getTafseerText(surah, ayah, identifier);
      if (localText != null && localText.trim().length > 5 && !localText.contains("تعذر") && !localText.contains("فشل")) {
        return {'text': _stripHtml(localText), 'name': tafseerName};
      }

      // 2. إذا لم يوجد، الاعتماد على TafseerService (Quran.com v4)
      final fallbackText = await TafseerService.getAyahTafseer(surah, ayah, tafseerId: tafseerId);
      
      if (!fallbackText.contains("فشل") && !fallbackText.contains("خطأ") && !fallbackText.contains("غير متوفر")) {
        final cleanText = _stripHtml(fallbackText);
        
        // حفظ في SQLite ليعمل أوفلاين في المرات القادمة
        final resourceId = await _quranDb.upsertResource({
          'name': tafseerName,
          'identifier': identifier,
          'type': 'tafseer',
          'lang': 'ar',
          'is_downloaded': 0, 
        });

        await _quranDb.saveTafseersBatch(resourceId, [
          {'verse_key': '$surah:$ayah', 'text': fallbackText} // Save raw, but return clean
        ]);

        return {'text': cleanText, 'name': tafseerName};
      }
      
      return {'text': _stripHtml(fallbackText), 'name': tafseerName};
    } catch (e) {
      debugPrint("❌ GetTafseer Error: $e");
      final tafseerId = preferredTafseerId ?? await TafseerService.getTafseerId();
      final tafseerName = TafseerService.availableTafseers[tafseerId] ?? 'التفسير';
      return {'text': "فشل جلب المعاني من الخادم. تأكد من اتصالك بالإنترنت.", 'name': tafseerName};
    }
  }

  // ======================================================================
  //  🌍 الترجمة — Translation (SQLite-first with Auto-cache)
  // ======================================================================

  /// جلب الترجمة لآية معينة (أوفلاين من SQLite)
  Future<String> getTranslation(int surah, int ayah, int translationId) async {
    final identifier = _getTranslationIdentifier(translationId);

    // 1. محاولة الجلب من SQLite
    final localText = await _quranDb.getTranslationText(surah, ayah, identifier);
    if (localText != null && localText.trim().length > 5 && !localText.contains("تعذر") && !localText.contains("فشل")) {
      return localText;
    }

    // 2. جلب من API باستخدام Quran.com v4 (الأكثر استقراراً)
    try {
      final response = await _dio.get(
        'https://api.quran.com/api/v4/quran/translations/$translationId',
        queryParameters: {'verse_key': '$surah:$ayah'},
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );

      if (response.statusCode == 200) {
        final List translations = response.data['translations'];
        if (translations.isNotEmpty) {
          final String text = _stripHtml(translations.first['text']);
          
          final resourceId = await _quranDb.upsertResource({
            'name': 'Translation $translationId',
            'identifier': identifier,
            'type': 'translation',
            'lang': 'en',
            'is_downloaded': 0,
          });

          await _quranDb.saveTranslationsBatch(resourceId, [
            {'verse_key': '$surah:$ayah', 'text': text}
          ]);
          
          return text;
        }
      }
      
      // Fallback 3: QuranEnc if Quran.com fails
      final encResponse = await _dio.get(
        'https://quranenc.com/api/v1/translation/aya/english_saheeh/$surah/$ayah',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      if (encResponse.statusCode == 200) {
        return _stripHtml(encResponse.data['result']?['translation'] ?? "الترجمة غير متاحة.");
      }

      return "الترجمة غير متاحة للآية $surah:$ayah.";
    } catch (e) {
      debugPrint("❌ GetTranslation Error: $e");
      return "عذراً، فشل الاتصال بخوادم الترجمة."; 
    }
  }

  String _stripHtml(String html) {
    // 1. Unescape common HTML entities
    var text = html
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    
    // 2. Remove all HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // 3. Remove multiple spaces and trim
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _getTranslationIdentifier(int id) {
    switch (id) {
      case 131: return 'en-sahih';
      case 139: return 'en-yusuf-ali';
      default: return 'translation-$id';
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
