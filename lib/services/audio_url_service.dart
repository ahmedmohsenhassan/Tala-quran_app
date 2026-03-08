import '../models/reciter_model.dart';

/// خدمة توليد روابط الصوت ديناميكياً
/// Service to generate audio URLs dynamically
class AudioUrlService {
  static const String _islamicNetworkBase =
      "https://cdn.islamic.network/quran/audio-surah/128";
  static const String _everyAyahBase = "https://everyayah.com/data";

  /// توليد رابط الملف الصوتي لسورة كاملة
  /// Generate a full Surah audio URL
  static String getSurahUrl({
    required Reciter reciter,
    required int surahNumber,
  }) {
    final String s = surahNumber.toString().padLeft(3, '0');

    // Prioritize the specific server URL if provided
    if (reciter.serverUrl.isNotEmpty) {
      String base = reciter.serverUrl;
      if (!base.endsWith('/')) base += '/';
      return "$base$s.mp3";
    }

    // Fallback to islamic.network pattern
    return "$_islamicNetworkBase/${reciter.identifier}/$surahNumber.mp3";
  }

  /// توليد رابط الملف الصوتي لآية محددة من everyayah.com
  /// Generate a specific Ayah audio URL from everyayah.com
  static String getAyahUrl({
    required String reciterBaseUrl,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final String s = surahNumber.toString().padLeft(3, '0');
    final String a = ayahNumber.toString().padLeft(3, '0');

    // Ensure the base URL ends with a slash
    String base = reciterBaseUrl;
    if (!base.endsWith('/')) {
      base += '/';
    }

    return "$base$s$a.mp3";
  }

  /// الحصول على القارئ المفضل من SharedPreferences (helper)
  /// This is a convenience method, the actual fetching happens in UI usually
  static Reciter getReciterById(String id) {
    return Reciter.defaultReciters.firstWhere(
      (r) => r.id == id,
      orElse: () => Reciter.defaultReciters.first,
    );
  }
}
