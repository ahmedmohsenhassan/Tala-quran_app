import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'quran_database_service.dart';
import 'audio_service.dart';
import 'audio_url_service.dart';
import '../models/reciter_model.dart';

/// 📥 خدمة تحميل موارد القرآن (تفسير، ترجمة)
/// Quran Resource Download Service
class QuranResourceService {
  final Dio _dio = Dio();
  final QuranDatabaseService _db = QuranDatabaseService();

  /// تحميل ترجمة كاملة وتخزينها في SQLite
  Future<void> downloadTranslation(int translationId, String identifier, String name) async {
    try {
      debugPrint('📥 [ResourceService] Starting download for translation: $name ($identifier)');
      
      // 1. إنشاء السجل في جدول المصادر
      final resourceId = await _db.upsertResource({
        'name': name,
        'identifier': identifier,
        'type': 'translation',
        'lang': 'en', // Default to en, can be dynamic
        'is_downloaded': 0,
      });

      // 2. جلب البيانات من API (النسخة الكاملة)
      // Note: api.quran.com v4 returns translations by resource ID
      final response = await _dio.get('https://api.quran.com/api/v4/quran/translations/$translationId');
      
      if (response.statusCode == 200) {
        final List translations = response.data['translations'];
        debugPrint('✅ [ResourceService] Fetched ${translations.length} ayahs. Saving to DB...');

        final List<Map<String, dynamic>> batch = translations.map((t) => {
          'verse_key': t['verse_key'],
          'text': _stripHtml(t['text']),
        }).toList();

        // 3. تخزين في SQLite
        await _db.saveTranslationsBatch(resourceId, batch);
        debugPrint('🎉 [ResourceService] Translation $identifier is now 100% offline.');
      }
    } catch (e) {
      debugPrint('❌ [ResourceService] Download failed: $e');
    }
  }

  /// تحميل تفسير كامل وتخزينها في SQLite
  Future<void> downloadTafseer(int tafseerId, String identifier, String name) async {
    try {
      debugPrint('📥 [ResourceService] Starting download for tafseer: $name ($identifier)');
      
      final resourceId = await _db.upsertResource({
        'name': name,
        'identifier': identifier,
        'type': 'tafseer',
        'lang': 'ar',
        'is_downloaded': 0,
      });

      // API: https://api.quran.com/api/v4/quran/tafsirs/{tafsir_id}
      final response = await _dio.get('https://api.quran.com/api/v4/quran/tafsirs/$tafseerId');
      
      if (response.statusCode == 200) {
        final List tafseers = response.data['tafsirs'];
        debugPrint('✅ [ResourceService] Fetched ${tafseers.length} tafseers. Saving to DB...');

        final List<Map<String, dynamic>> batch = tafseers.map((t) => {
          'verse_key': t['verse_key'],
          'text': _stripHtml(t['text']),
        }).toList();

        await _db.saveTafseersBatch(resourceId, batch);
        debugPrint('🎉 [ResourceService] Tafseer $identifier is now 100% offline.');
      }
    } catch (e) {
      debugPrint('❌ [ResourceService] Download failed: $e');
    }
  }

  /// تحميل ملف صوتي لسورة كاملة وتخزينه محلياً
  Future<void> downloadSurahAudio({
    required Reciter reciter,
    required int surahNumber,
    required String surahName,
  }) async {
    try {
      final file = await AudioService.getSurahFile(reciter.id, surahNumber);
      if (await file.exists()) return; // Already downloaded

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      final url = AudioUrlService.getSurahUrl(reciter: reciter, surahNumber: surahNumber);
      debugPrint('📥 [ResourceService] Downloading Audio: $url -> ${file.path}');

      await _dio.download(
        url,
        file.path,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            // progress logic here if needed for UI stream
          }
        },
      );

      // Save to resources table for management
      await _db.upsertResource({
        'name': 'تلاوة سورة $surahName',
        'identifier': 'audio_${reciter.id}_$surahNumber',
        'type': 'audio',
        'lang': reciter.id,
        'is_downloaded': 1,
      });

      debugPrint('🎉 [ResourceService] Audio for Surah $surahNumber (${reciter.name}) downloaded.');
    } catch (e) {
      debugPrint('❌ [ResourceService] Audio Download failed: $e');
      rethrow;
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
  }
}
