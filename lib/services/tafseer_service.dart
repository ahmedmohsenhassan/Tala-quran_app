import 'package:dio/dio.dart';

/// خدمة التفسير
/// Tafseer service for fetching Ayah explanations
class TafseerService {
  static final Dio _dio = Dio();

  // استخدام مشروع QuranEnc للتفسير الميسر
  // Using QuranEnc API for Arabic Tafseer Al-Muyassar
  static const String _baseUrl = 'https://quranenc.com/api/v1/translation/ayah';

  /// الحصول على تفسير آية معينة
  /// Get tafseer for a specific Ayah
  static Future<String> getAyahTafseer(int surahNumber, int ayahNumber) async {
    try {
      final response =
          await _dio.get('$_baseUrl/arabic_moyassar/$surahNumber/$ayahNumber');

      if (response.statusCode == 200) {
        return response.data['result']['translation'] ??
            'المحتوى غير متوفر حالياً.';
      } else {
        return 'فشل الاتصال بخادم التفسير.';
      }
    } catch (e) {
      return 'حدث خطأ أثناء تحميل التفسير: $e';
    }
  }

  /// الحصول على كل تفاسير سورة معينة
  /// Get all tafseers for a specific Surah
  static Future<List<Map<String, dynamic>>> getSurahTafseer(
      int surahNumber) async {
    try {
      final response = await _dio.get(
        'https://quranenc.com/api/v1/translation/sura/arabic_moyassar/$surahNumber',
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['result']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
