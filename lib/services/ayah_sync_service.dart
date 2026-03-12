import 'package:dio/dio.dart';
import '../models/ayah_coordinate.dart';
import '../models/reciter_model.dart';

/// خدمة مزامنة الآيات (توقيتات + إحداثيات)
/// Ayah Synchronization Service (Timings + Coordinates)
class AyahSyncService {
  static final AyahSyncService _instance = AyahSyncService._internal();
  factory AyahSyncService() => _instance;
  AyahSyncService._internal();

  final Dio _dio = Dio();

  // ذاكرة مؤقتة للتوقيتات - Cache for timings
  final Map<String, List<Map<String, dynamic>>> _timingsCache = {};

  /// جلب توقيتات الآيات لسورة معينة وقارئ معين
  /// Fetch verse timings for a surah and reciter
  Future<List<Map<String, dynamic>>> getVerseTimings({
    required int surahNumber,
    required Reciter reciter,
  }) async {
    final cacheKey = '${reciter.id}_$surahNumber';
    if (_timingsCache.containsKey(cacheKey)) {
      return _timingsCache[cacheKey]!;
    }

    try {
      // استخدام API quran.com لجلب التوقيتات
      // Using quran.com API for timings
      // Note: Recitation IDs differ from identifiers. Defaulting to a common one if needed.
      // For now, let's use a mapping or a standard one for demo.
      final recitationId = _getRecitationId(reciter.id);
      
      final response = await _dio.get(
        'https://api.quran.com/api/v4/recitations/$recitationId/by_chapter/$surahNumber',
        queryParameters: {'per_page': 300},
      );

      if (response.statusCode == 200) {
        final List timings = response.data['audio_files'];
        if (timings.isNotEmpty && timings[0]['verse_timings'] != null) {
          final List vTimings = timings[0]['verse_timings'];
          final result = vTimings.map((t) => {
            'ayahNumber': int.parse(t['verse_key'].split(':')[1]),
            'timestampFrom': t['timestamp_from'],
            'timestampTo': t['timestamp_to'],
          }).toList();
          
          _timingsCache[cacheKey] = result;
          return result;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// جلب إحداثيات الآيات لصفحة معينة
  /// Fetch Ayah coordinates for a specific page
  Future<List<AyahCoordinate>> getPageCoordinates(int pageNumber) async {
    // Al-Fatiha (Page 1) coordinates - Approximate for 1024x1656 image
    if (pageNumber == 1) {
      return [
        AyahCoordinate(surahNumber: 1, ayahNumber: 1, pageNumber: 1, minX: 100, maxX: 924, minY: 375, maxY: 460),
        AyahCoordinate(surahNumber: 1, ayahNumber: 2, pageNumber: 1, minX: 100, maxX: 924, minY: 485, maxY: 570),
        AyahCoordinate(surahNumber: 1, ayahNumber: 3, pageNumber: 1, minX: 100, maxX: 924, minY: 600, maxY: 685),
        AyahCoordinate(surahNumber: 1, ayahNumber: 4, pageNumber: 1, minX: 100, maxX: 924, minY: 715, maxY: 800),
        AyahCoordinate(surahNumber: 1, ayahNumber: 5, pageNumber: 1, minX: 100, maxX: 924, minY: 830, maxY: 920),
        AyahCoordinate(surahNumber: 1, ayahNumber: 6, pageNumber: 1, minX: 100, maxX: 924, minY: 945, maxY: 1030),
        AyahCoordinate(surahNumber: 1, ayahNumber: 7, pageNumber: 1, minX: 100, maxX: 924, minY: 1055, maxY: 1250),
      ];
    }
    
    // Al-Baqarah (Page 2) coordinates
    if (pageNumber == 2) {
      return [
        AyahCoordinate(surahNumber: 2, ayahNumber: 1, pageNumber: 2, minX: 100, maxX: 924, minY: 150, maxY: 230),
        AyahCoordinate(surahNumber: 2, ayahNumber: 2, pageNumber: 2, minX: 100, maxX: 924, minY: 250, maxY: 330),
        AyahCoordinate(surahNumber: 2, ayahNumber: 3, pageNumber: 2, minX: 100, maxX: 924, minY: 350, maxY: 430),
        AyahCoordinate(surahNumber: 2, ayahNumber: 4, pageNumber: 2, minX: 100, maxX: 924, minY: 450, maxY: 530),
        AyahCoordinate(surahNumber: 2, ayahNumber: 5, pageNumber: 2, minX: 100, maxX: 924, minY: 550, maxY: 630),
      ];
    }
    
    try {
      // Placeholder for other pages
      return [];
    } catch (e) {
      return [];
    }
  }

  int _getRecitationId(String reciterId) {
    // Mapping our IDs to Quran.com recitation IDs
    // 7 = Mishary Rashid Alafasy
    // 6 = Mahmoud Khalil Al-Husary
    // 12 = Mohamed Siddiq El-Minshawi
    // 3 = Saad Al-Ghamdi
    final mapping = {
      'al_afasy': 7,
      'al_husary_hafs': 6,
      'al_husary_warsh': 6, // Approximate for demo
      'al_minshawi': 12,
      'al_ghamdi': 3,
    };
    return mapping[reciterId] ?? 7;
  }
}
