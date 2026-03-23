import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'quran_database_service.dart';

class RecitationRecognitionService {
  static final RecitationRecognitionService _instance = RecitationRecognitionService._internal();
  factory RecitationRecognitionService() => _instance;
  RecitationRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInit = false;

  Future<RecognitionResult?> recognizeAyah() async {
    try {
      // 1. Permissions
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          debugPrint('⚠️ Microphone permission denied.');
          return null;
        }
      }

      // 2. Initialize
      if (!_isInit) {
        _isInit = await _speech.initialize(
          onStatus: (status) => debugPrint('🎙️ Speech Status: $status'),
          onError: (error) => debugPrint('❌ Speech Error: $error'),
        );
      }

      if (!_isInit) {
        debugPrint('⚠️ Speech recognition unavailable on this device.');
        return null;
      }

      // 3. Start Listening (Fixed duration: 4 seconds)
      String recognizedText = "";
      
      await _speech.listen(
        onResult: (result) {
          recognizedText = result.recognizedWords;
          debugPrint('🗣️ Hearing: $recognizedText');
        },
        localeId: 'ar_SA', // Arabic (Saudi Arabia) helps with Quranic pronunciation
        listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      );

      // Wait 4 seconds for the user to recite a recognizable phrase
      await Future.delayed(const Duration(seconds: 4));
      
      // Stop the microphone
      await _speech.stop();

      // Ensure we got something
      if (recognizedText.trim().isEmpty) {
        debugPrint('⚠️ No speech transcribed.');
        return null;
      }

      debugPrint('✅ Transcribed Speech: $recognizedText');

      // 4. 🔥 المحرك المحلي القوي (100% Offline)
      // نستخدم محرك FTS5 المحلي للبحث عن التطابق
      final searchResults = await QuranDatabaseService().searchVerses(recognizedText);

      if (searchResults.isNotEmpty) {
        final bestMatch = searchResults[0];
        
        final surah = int.parse(bestMatch['surahNumber']);
        final ayah = int.parse(bestMatch['verseNumber']);
        final textClean = bestMatch['text'] as String;

        debugPrint('🎯 Match Found Locally: Surah $surah, Ayah $ayah');

        return RecognitionResult(
          surah: surah,
          ayah: ayah,
          text: textClean,
          confidence: 0.95,
        );
      }

      debugPrint('⚠️ No local Quranic matches found for the transcription.');
      return null;

    } catch (e) {
      debugPrint('❌ Error in Recitation Identification: $e');
      return null;
    }
  }
}

class RecognitionResult {
  final int surah;
  final int ayah;
  final String text;
  final double confidence;

  RecognitionResult({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.confidence,
  });
}
