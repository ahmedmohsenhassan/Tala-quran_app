import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class AITajweedService {
  static final AITajweedService _instance = AITajweedService._internal();
  factory AITajweedService() => _instance;
  AITajweedService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final Dio _dio = Dio();
  bool _isInit = false;
  String _currentTranscription = "";

  Future<bool> startRecording() async {
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) return false;
      }

      if (!_isInit) {
        _isInit = await _speech.initialize(
          onStatus: (status) => debugPrint('Tajweed Speech Status: $status'),
          onError: (error) => debugPrint('Tajweed Speech Error: $error'),
        );
      }

      if (!_isInit) return false;

      await _speech.listen(
        onResult: (result) {
          _currentTranscription = result.recognizedWords;
        },
        localeId: 'ar_SA',
        listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      );

      return true;
    } catch (e) {
      debugPrint('Error starting tajweed recognition: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Ensure final words are caught
      await _speech.stop();
      return _currentTranscription.trim().isNotEmpty ? _currentTranscription : null;
    } catch (e) {
      debugPrint('Error stopping tajweed recognition: $e');
      return null;
    }
  }

  Future<List<TajweedResult>> analyzeRecitation(String transcribedText, int surah, int ayah) async {
    try {
      // 1. Fetch exact Uthmani text from API
      // We use simple text since voice transcription doesn't include diacritics
      final response = await _dio.get(
        'https://api.quran.com/api/v4/verses/by_key/$surah:$ayah',
        queryParameters: {
          'fields': 'text_simple',
        },
      );

      if (response.statusCode != 200) throw Exception('API failed');
      
      final verseData = response.data['verse'];
      final targetText = verseData['text_simple'] as String;

      debugPrint('🎯 Target Ayah: $targetText');
      debugPrint('🗣️ Spoken Text: $transcribedText');

      // 2. Perform normalized word matching
      return _compareRecitation(targetText, transcribedText);

    } catch (e) {
      debugPrint('❌ Error analyzing tajweed: $e');
      // Fallback response if offline
      return [
        TajweedResult(
          word: "تعذر",
          status: TajweedStatus.error,
          feedback: "يرجى التحقق من اتصال الإنترنت لجلب النص.",
        ),
      ];
    }
  }

  String _normalizeArabic(String input) {
    String result = input.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), ''); // Remove Tashkeel
    result = result.replaceAll(RegExp(r'[إأآا]'), 'ا');
    result = result.replaceAll(RegExp(r'[يى]'), 'ي');
    result = result.replaceAll(RegExp(r'[ةه]'), 'ه');
    result = result.replaceAll(RegExp(r'[ؤئ]'), 'ء');
    return result;
  }

  List<TajweedResult> _compareRecitation(String targetText, String spokenText) {
    final targetWords = targetText.split(' ').where((w) => w.trim().isNotEmpty).toList();
    final spokenWords = spokenText.split(' ').where((w) => w.trim().isNotEmpty).toList();
    final results = <TajweedResult>[];

    int spokenIndex = 0;

    for (String targetWord in targetWords) {
      final normTarget = _normalizeArabic(targetWord);
      
      if (spokenIndex < spokenWords.length) {
        final normSpoken = _normalizeArabic(spokenWords[spokenIndex]);
        
        if (normTarget == normSpoken) {
          // Perfect match
          results.add(TajweedResult(word: targetWord, status: TajweedStatus.correct, feedback: "نطق صحيح وجيد"));
          spokenIndex++;
        } else if (normTarget.contains(normSpoken) || normSpoken.contains(normTarget)) {
          // Partial match (e.g. slight mispronunciation picked up by STT)
          results.add(TajweedResult(word: targetWord, status: TajweedStatus.warning, feedback: "انتبه لمخارج الحروف والتشكيل"));
          spokenIndex++;
        } else {
          // Mismatch, check if the user skipped a word and the next one matches
          if (spokenIndex + 1 < spokenWords.length && _normalizeArabic(spokenWords[spokenIndex + 1]) == normTarget) {
            results.add(TajweedResult(word: targetWord, status: TajweedStatus.correct, feedback: "نطق صحيح"));
            spokenIndex += 2;
          } else {
            results.add(TajweedResult(word: targetWord, status: TajweedStatus.error, feedback: "خطأ في النطق أو تم تخطي الكلمة"));
          }
        }
      } else {
        // Did not finish the ayah
        results.add(TajweedResult(word: targetWord, status: TajweedStatus.error, feedback: "لم يتم استكمال قراءة الكلمة"));
      }
    }

    return results;
  }

  void dispose() {
    _speech.cancel();
  }
}

enum TajweedStatus { correct, warning, error }

class TajweedResult {
  final String word;
  final TajweedStatus status;
  final String feedback;

  TajweedResult({
    required this.word,
    required this.status,
    required this.feedback,
  });
}
