import 'package:flutter/foundation.dart';
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

  // Cache for timings and coordinates
  final Map<String, List<Map<String, dynamic>>> _timingsCache = {};
  final Map<int, List<AyahCoordinate>> _coordinatesCache = {};

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
      final recitationId = _getRecitationId(reciter.id);
      debugPrint('🌐 Fetching timings for Surah $surahNumber, Reciter $recitationId...');
      
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
          
          debugPrint('✅ Fetched ${result.length} timings for Surah $surahNumber');
          _timingsCache[cacheKey] = result;
          return result;
        } else {
          debugPrint('⚠️ No timings found in response for Surah $surahNumber');
        }
      } else {
        debugPrint('❌ API Error ${response.statusCode} for timings Surah $surahNumber');
      }
      return [];
    } catch (e) {
      debugPrint('❌ Exception fetching timings: $e');
      return [];
    }
  }

  /// جلب إحداثيات الآيات لصفحة معينة
  /// Fetch Ayah coordinates for a specific page
  Future<List<AyahCoordinate>> getPageCoordinates(int pageNumber) async {
    // Use cache if available
    if (_coordinatesCache.containsKey(pageNumber)) {
      return _coordinatesCache[pageNumber]!;
    }

    // Al-Fatiha (Page 1) coordinates
    if (pageNumber == 1) {
      final coords = [
        AyahCoordinate(surahNumber: 1, ayahNumber: 1, pageNumber: 1, minX: 100, maxX: 924, minY: 375, maxY: 460),
        AyahCoordinate(surahNumber: 1, ayahNumber: 2, pageNumber: 1, minX: 100, maxX: 924, minY: 485, maxY: 570),
        AyahCoordinate(surahNumber: 1, ayahNumber: 3, pageNumber: 1, minX: 100, maxX: 924, minY: 600, maxY: 685),
        AyahCoordinate(surahNumber: 1, ayahNumber: 4, pageNumber: 1, minX: 100, maxX: 924, minY: 715, maxY: 800),
        AyahCoordinate(surahNumber: 1, ayahNumber: 5, pageNumber: 1, minX: 100, maxX: 924, minY: 830, maxY: 920),
        AyahCoordinate(surahNumber: 1, ayahNumber: 6, pageNumber: 1, minX: 100, maxX: 924, minY: 945, maxY: 1030),
        AyahCoordinate(surahNumber: 1, ayahNumber: 7, pageNumber: 1, minX: 100, maxX: 924, minY: 1055, maxY: 1250),
      ];
      _coordinatesCache[pageNumber] = coords;
      return coords;
    }
    
    // Al-Baqarah (Page 2) coordinates
    if (pageNumber == 2) {
      final coords = [
        AyahCoordinate(surahNumber: 2, ayahNumber: 1, pageNumber: 2, minX: 100, maxX: 924, minY: 150, maxY: 230),
        AyahCoordinate(surahNumber: 2, ayahNumber: 2, pageNumber: 2, minX: 100, maxX: 924, minY: 250, maxY: 330),
        AyahCoordinate(surahNumber: 2, ayahNumber: 3, pageNumber: 2, minX: 100, maxX: 924, minY: 350, maxY: 430),
        AyahCoordinate(surahNumber: 2, ayahNumber: 4, pageNumber: 2, minX: 100, maxX: 924, minY: 450, maxY: 530),
        AyahCoordinate(surahNumber: 2, ayahNumber: 5, pageNumber: 2, minX: 100, maxX: 924, minY: 550, maxY: 630),
      ];
      _coordinatesCache[pageNumber] = coords;
      return coords;
    }
    
    // Dynamic coordinate generation with retry logic
    int retries = 3;
    while (retries > 0) {
      try {
        final response = await _dio.get(
          'https://api.quran.com/api/v4/verses/by_page/$pageNumber',
          queryParameters: {
            'words': 'true',
            'word_fields': 'line_number',
          },
          options: Options(
            sendTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200) {
          final List verses = response.data['verses'];
          final List<AyahCoordinate> generatedCoords = [];

          const double topOffset = 150;
          const double lineHeight = 95;
          const int leftPadding = 80;
          const int rightPadding = 80;

          for (var v in verses) {
            final int surah = v['verse_key'].split(':').map(int.parse).first;
            final int ayah = v['verse_key'].split(':').map(int.parse).last;
            final List words = v['words'];
            final Set<int> lines = words.map((w) => w['line_number'] as int).toSet();
            
            for (int line in lines) {
              final int minY = (topOffset + (line - 1) * lineHeight).toInt();
              final int maxY = (minY + lineHeight - 10).toInt();

              generatedCoords.add(AyahCoordinate(
                surahNumber: surah,
                ayahNumber: ayah,
                pageNumber: pageNumber,
                minX: leftPadding,
                maxX: 1024 - rightPadding,
                minY: minY,
                maxY: maxY,
              ));
            }
          }

          debugPrint('✅ Generated ${generatedCoords.length} coordinate boxes for page $pageNumber');
          _coordinatesCache[pageNumber] = generatedCoords;
          return generatedCoords;
        }
        break;
      } catch (e) {
        retries--;
        if (retries == 0) {
          debugPrint('Error generating coordinates for page $pageNumber: $e');
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    return [];
  }

  int _getRecitationId(String reciterId) {
    final mapping = {
      'al_afasy': 7,
      'al_husary_hafs': 6,
      'al_husary_warsh': 6,
      'al_minshawi': 12,
      'al_ghamdi': 3,
    };
    return mapping[reciterId] ?? 7;
  }
}
