import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التفسير
/// Tafseer service for fetching Ayah explanations
class TafseerService {
  static final Dio _dio = Dio();
  
  // --- إعدادات وتفضيلات التفسير (Preferences) ---
  static const String _tafseerLanguageKey = 'app_tafseer_id';

  // معرّفات التفاسير المتاحة بناءً على api.quran.com
  // 16: Tafseer Al-Jalalayn (Arabic) - Default
  // 169: Tafsir Ibn Kathir (Arabic)
  // 91: Tafsir Al-Sa'di (Arabic)
  // 164: Tafsir Al-Muyassar (Arabic)
  // 170: Tafsir Al-Baghawi (Arabic)
  static const int tafseerJalalayn = 16;
  static const int tafseerIbnKathir = 169;
  static const int tafseerSaadi = 91;
  static const int tafseerMuyassar = 164;
  static const int tafseerBaghawi = 170;

  static const Map<int, String> availableTafseers = {
    tafseerJalalayn: 'تفسير الجلالين',
    tafseerIbnKathir: 'تفسير ابن كثير',
    tafseerSaadi: 'تفسير السعدي',
    tafseerMuyassar: 'التفسير الميسر',
    tafseerBaghawi: 'تفسير البغوي',
  };

  /// الحصول على معرف التفسير الحالي
  static Future<int> getTafseerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tafseerLanguageKey) ?? tafseerJalalayn;
  }

  /// تغيير التفسير
  static Future<void> setTafseerId(int tafseerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tafseerLanguageKey, tafseerId);
  }


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
