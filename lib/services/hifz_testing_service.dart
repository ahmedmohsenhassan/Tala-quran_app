import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'hifz_database_service.dart';

class HifzTestingService {
  static final HifzTestingService _instance = HifzTestingService._internal();
  factory HifzTestingService() => _instance;
  HifzTestingService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final Dio _dio = Dio();
  final HifzDatabaseService _dbService = HifzDatabaseService();
  bool _isInit = false;
  String _currentTranscription = "";

  /// Start listening to the user's recitation for the test
  Future<bool> startHifzTest() async {
    try {
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) return false;
      }

      if (!_isInit) {
        _isInit = await _speech.initialize(
          onStatus: (status) => debugPrint('Hifz Speech Status: $status'),
          onError: (error) => debugPrint('Hifz Speech Error: $error'),
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
      debugPrint('Error starting Hifz testing: $e');
      return false;
    }
  }

  /// Stop listening and return the transcribed text
  Future<String?> finishHifzTest() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Ensure final words are caught
      await _speech.stop();
      return _currentTranscription.trim().isNotEmpty ? _currentTranscription : null;
    } catch (e) {
      debugPrint('Error stopping Hifz testing: $e');
      return null;
    }
  }

  /// Evaluates the recitation against the actual Quran text, saves the score, and returns the analysis.
  Future<HifzTestResult> evaluateRecitation(String transcribedText, int surah, int ayah) async {
    try {
      // 1. Fetch exact Uthmani text from API
      final response = await _dio.get(
        'https://api.quran.com/api/v4/verses/by_key/$surah:$ayah',
        queryParameters: {
          'fields': 'text_simple',
        },
      );

      if (response.statusCode != 200) throw Exception('API failed');
      
      final verseData = response.data['verse'];
      final targetText = verseData['text_simple'] as String;

      debugPrint('🎯 Target Ayah (Hifz): $targetText');
      debugPrint('🗣️ Spoken Text (Hifz): $transcribedText');

      // 2. Perform normalized word matching and grading
      final result = _gradeRecitation(targetText, transcribedText, surah, ayah);
      
      // 3. Save to database
      await _dbService.saveTestResult(surah, ayah, result.scorePercentage);

      return result;

    } catch (e) {
      debugPrint('❌ Error evaluating Hifz test: $e');
      return HifzTestResult(
        scorePercentage: 0.0,
        wordDetails: [
          HifzWordDetail(word: "تعذر التقييم", isCorrect: false, feedback: "تأكد من اتصالك بالإنترنت")
        ],
      );
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

  HifzTestResult _gradeRecitation(String targetText, String spokenText, int surah, int ayah) {
    final targetWords = targetText.split(' ').where((w) => w.trim().isNotEmpty).toList();
    final spokenWords = spokenText.split(' ').where((w) => w.trim().isNotEmpty).toList();
    final details = <HifzWordDetail>[];
    
    int correctCount = 0;
    int spokenIndex = 0;

    for (String targetWord in targetWords) {
      final normTarget = _normalizeArabic(targetWord);
      
      if (spokenIndex < spokenWords.length) {
        final normSpoken = _normalizeArabic(spokenWords[spokenIndex]);
        
        if (normTarget == normSpoken || normTarget.contains(normSpoken) || normSpoken.contains(normTarget)) {
          // Accept exact matches or close partials (API transcription variations) as "Memorized"
          details.add(HifzWordDetail(word: targetWord, isCorrect: true, feedback: ""));
          correctCount++;
          spokenIndex++;
        } else {
          // Mismatch, check if the user skipped a word and the next one matches
          if (spokenIndex + 1 < spokenWords.length && _normalizeArabic(spokenWords[spokenIndex + 1]) == normTarget) {
            details.add(HifzWordDetail(word: targetWord, isCorrect: true, feedback: ""));
            correctCount++;
            spokenIndex += 2;
          } else {
            details.add(HifzWordDetail(word: targetWord, isCorrect: false, feedback: "كلمة مفقودة أو خطأ"));
          }
        }
      } else {
        // User stopped before finishing the ayah
        details.add(HifzWordDetail(word: targetWord, isCorrect: false, feedback: "لم تقرأها"));
      }
    }

    double score = targetWords.isNotEmpty ? (correctCount / targetWords.length) : 0.0;
    // Penalty if they spoke way too many extra words
    if (spokenWords.length > targetWords.length + 3) {
      score -= 0.1;
    }
    score = score.clamp(0.0, 1.0);

    return HifzTestResult(
      scorePercentage: score,
      wordDetails: details,
    );
  }

  void dispose() {
    _speech.cancel();
  }
}

class HifzTestResult {
  final double scorePercentage; // 0.0 to 1.0
  final List<HifzWordDetail> wordDetails;

  HifzTestResult({
    required this.scorePercentage,
    required this.wordDetails,
  });
}

class HifzWordDetail {
  final String word;
  final bool isCorrect;
  final String feedback;

  HifzWordDetail({
    required this.word,
    required this.isCorrect,
    required this.feedback,
  });
}
