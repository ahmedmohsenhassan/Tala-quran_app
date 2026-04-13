import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_database_service.dart';

/// خدمة التفسير
/// Tafseer service for fetching Ayah explanations
class TafseerService {
  static final Dio _dio = Dio();
  static final QuranDatabaseService _db = QuranDatabaseService();
  
  // --- إعدادات وتفضيلات التفسير (Preferences) ---
  static const String _tafseerLanguageKey = 'app_tafseer_id';

  // معرّفات التفاسير المتاحة بناءً على api.quran.com
  // 16: Tafseer Al-Jalalayn (Arabic)
  // 169: Tafsir Ibn Kathir (Arabic)
  // 91: Tafsir Al-Sa'di (Arabic)
  // 164: Tafsir Al-Muyassar (Arabic) - Default
  // 170: Tafsir Al-Baghawi (Arabic)
  static const int tafseerJalalayn = 16;
  static const int tafseerIbnKathir = 169;
  static const int tafseerSaadi = 91;
  static const int tafseerMuyassar = 164;
  static const int tafseerBaghawi = 170;

  static const Map<int, String> availableTafseers = {
    tafseerMuyassar: 'التفسير الميسر',
    tafseerSaadi: 'تفسير السعدي',
    tafseerJalalayn: 'تفسير الجلالين',
    tafseerIbnKathir: 'تفسير ابن كثير',
    tafseerBaghawi: 'تفسير البغوي',
  };

  /// الحصول على معرف التفسير الحالي
  static Future<int> getTafseerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tafseerLanguageKey) ?? tafseerMuyassar;
  }

  /// تغيير التفسير
  static Future<void> setTafseerId(int tafseerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tafseerLanguageKey, tafseerId);
  }

  // استخدام Quran.com v4 API
  static const String _baseUrl = 'https://api.quran.com/api/v4';

  /// الحصول على تفسير آية معينة
  /// Get tafseer for a specific Ayah (Local first)
  static Future<String> getAyahTafseer(int surahNumber, int ayahNumber, {int? tafseerId}) async {
    final id = tafseerId ?? await getTafseerId();
    final identifier = 'tafseer-$id';

    // 1. حاول البحث محلياً أولاً
    final localText = await _db.getTafseerText(surahNumber, ayahNumber, identifier);
    if (localText != null && localText.trim().isNotEmpty) {
      return localText;
    }

    // 2. الجلب من الإنترنت في حال عدم الوجود محلياً
    try {
      final response = await _dio.get('$_baseUrl/tafsirs/$id/by_ayah/$surahNumber:$ayahNumber');

      if (response.statusCode == 200) {
        return response.data['tafsir']['text'] ?? 'المحتوى غير متوفر حالياً.';
      } else {
        return 'فشل الاتصال بخادم التفسير.';
      }
    } catch (e) {
      return 'حدث خطأ أثناء تحميل التفسير: $e';
    }
  }

  /// الحصول على كل تفاسير سورة معينة (محلي أو أونلاين)
  /// Get all tafseers for a specific Surah
  static Future<List<Map<String, dynamic>>> getSurahTafseer(int surahNumber) async {
    final id = await getTafseerId();
    final identifier = 'tafseer-$id';

    // 1. تحقق من الوجود المحلي لتقليل استهلاك الإنترنت
    final isDownloaded = await _db.isResourceDownloaded(identifier);
    if (isDownloaded) {
      final local = await _db.getSurahTafseer(surahNumber, identifier);
      if (local.isNotEmpty) return local;
    }

    // 2. الجلب دفعة واحدة من API
    try {
      final response = await _dio.get(
        '$_baseUrl/quran/tafsirs/$id', 
        queryParameters: {'chapter_number': surahNumber}
      );

      if (response.statusCode == 200) {
        final List raw = response.data['tafsirs'];
        return raw.map((t) => {
          'verse_key': t['verse_key'],
          'text': t['text'],
          'aya': (t['verse_key'] as String).split(':').last,
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
