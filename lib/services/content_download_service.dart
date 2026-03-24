import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'quran_database_service.dart';

/// 📥 خدمة تحميل المحتوى — Content Download Service
/// مسؤولة عن تحميل التراجم والتفاسير كاملة للاستخدام أوفلاين
class ContentDownloadService extends ChangeNotifier {
  static final ContentDownloadService _instance = ContentDownloadService._internal();
  factory ContentDownloadService() => _instance;
  ContentDownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final QuranDatabaseService _db = QuranDatabaseService();

  // الحالة الحالية للتحميل
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  double _progress = 0;
  double get progress => _progress;

  String _statusMessage = "";
  String get statusMessage => _statusMessage;

  /// تحميل ترجمة معينة بالكامل
  Future<bool> downloadTranslation(int translationId, String name, String lang) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _progress = 0;
    _statusMessage = "بدء تحميل ترجمة: $name";
    notifyListeners();

    try {
      final identifier = 'translation-$translationId';
      
      // 1. تسجيل المصدر في قاعدة البيانات
      final resourceId = await _db.upsertResource({
        'name': name,
        'identifier': identifier,
        'type': 'translation',
        'lang': lang,
        'is_downloaded': 0,
      });

      // 2. التحميل سورة بسورة لتجنب الضغط على الذاكرة
      for (int surah = 1; surah <= 114; surah++) {
        _statusMessage = "جاري تحميل سورة $surah/114...";
        _progress = surah / 114;
        notifyListeners();

        final response = await _dio.get(
          'https://api.quran.com/api/v4/quran/translations/$translationId',
          queryParameters: {
            'chapter_number': surah,
          },
        );

        if (response.statusCode == 200) {
          final List translations = response.data['translations'];
          final batch = translations.map((t) => {
            'verse_key': t['verse_key'],
            'text': _stripHtml(t['text'] ?? ""),
          }).toList();

          await _db.saveTranslationsBatch(resourceId, batch);
        } else {
          throw Exception("فشل الاتصال بالخادم عند السورة $surah");
        }
      }

      _statusMessage = "تم تحميل الترجمة بنجاح! 🎉";
      _progress = 1.0;
      _isDownloading = false;
      notifyListeners();
      return true;

    } catch (e) {
      debugPrint('❌ Download Error: $e');
      _statusMessage = "فشل التحميل: $e";
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  /// تحميل تفسير معين بالكامل
  Future<bool> downloadTafseer(int tafseerId, String name, String lang) async {
    if (_isDownloading) return false;

    _isDownloading = true;
    _progress = 0;
    _statusMessage = "بدء تحميل تفسير: $name";
    notifyListeners();

    try {
      final identifier = 'tafseer-$tafseerId';
      
      final resourceId = await _db.upsertResource({
        'name': name,
        'identifier': identifier,
        'type': 'tafseer',
        'lang': lang,
        'is_downloaded': 0,
      });

      for (int surah = 1; surah <= 114; surah++) {
        _statusMessage = "جاري تحميل سورة $surah/114...";
        _progress = surah / 114;
        notifyListeners();

        final response = await _dio.get(
          'https://api.quran.com/api/v4/quran/tafsirs/$tafseerId',
          queryParameters: {
            'chapter_number': surah,
          },
        );

        if (response.statusCode == 200) {
          final List tafsirs = response.data['tafsirs'];
          final batch = tafsirs.map((t) => {
            'verse_key': t['verse_key'],
            'text': _stripHtml(t['text'] ?? ""),
          }).toList();

          await _db.saveTafseersBatch(resourceId, batch);
        }
      }

      _statusMessage = "تم تحميل التفسير بنجاح! 🎉";
      _progress = 1.0;
      _isDownloading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _statusMessage = "فشل التحميل: $e";
      _isDownloading = false;
      notifyListeners();
      return false;
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
  }
}
