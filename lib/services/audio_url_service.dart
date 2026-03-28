import '../models/reciter_model.dart';

/// خدمة توليد روابط الصوت ديناميكياً
/// Service to generate audio URLs dynamically
class AudioUrlService {
  static const String _islamicNetworkBase =
      "https://cdn.islamic.network/quran/audio-surah/128";

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
  
  /// توليد رابط Firebase Storage للملف الصوتي
  /// Generate a Firebase Storage audio URL
  static String getFirebaseAyahUrl({
    required String firebasePath,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final String s = surahNumber.toString().padLeft(3, '0');
    final String a = ayahNumber.toString().padLeft(3, '0');
    const String bucket = "tala-al-quran-db80c.firebasestorage.app";
    
    // Construct Path: e.g. reciters/minshowy/001001.mp3
    final String fullPath = "$firebasePath/$s$a.mp3";
    final String encodedPath = Uri.encodeComponent(fullPath);
    
    return "https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media";
  }

  /// توليد رابط الملف الصوتي لصفحة محددة (مصحف المدينة)
  /// Generate a page-specific audio URL
  static String getPageUrl({
    required Reciter reciter,
    required int pageNumber,
  }) {
    final String p = pageNumber.toString().padLeft(3, '0');

    // Use specific servers known for page-by-page mp3
    if (reciter.id.contains('warsh')) {
      // Warsh logic: use specific warsh server if available
      return 'https://server10.mp3quran.net/warsh/husr/$p.mp3';
    }

    // Default Hafs logic
    if (reciter.id == 'al_afasy') {
      return 'https://server8.mp3quran.net/afs/$p.mp3';
    }

    // Fallback for Al-Husary Hafs
    return 'https://server13.mp3quran.net/husr/$p.mp3';
  }

  /// الحصول على القارئ المفضل من SharedPreferences (helper)
  static Reciter getReciterById(String id) {
    try {
      return Reciter.defaultReciters.firstWhere((r) => r.id == id);
    } catch (_) {
      // Return a safe default if ID changes or is invalid
      return Reciter.defaultReciters.firstWhere(
        (r) => r.id.contains('afasy') || r.id.contains('hafs'),
        orElse: () => Reciter.defaultReciters.first,
      );
    }
  }
}
