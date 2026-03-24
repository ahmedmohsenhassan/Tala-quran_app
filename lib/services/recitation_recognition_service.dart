import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'quran_database_service.dart';

class RecitationRecognitionService extends ChangeNotifier {
  static final RecitationRecognitionService _instance = RecitationRecognitionService._internal();
  factory RecitationRecognitionService() => _instance;
  RecitationRecognitionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInit = false;
  bool _isListening = false;
  bool get isListening => _isListening;

  // 📡 Stream Controller for real-time word matches
  final StreamController<int> _wordMatchController = StreamController<int>.broadcast();
  Stream<int> get wordMatchStream => _wordMatchController.stream;

  List<String> _expectedWords = [];
  int _currentWordIndex = 0;
  String _lastRecognizedText = "";

  Future<bool> initialize() async {
    if (_isInit) return true;
    try {
      _isInit = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎙️ Speech Status: $status');
          if (status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) => debugPrint('❌ Speech Error: $error'),
      );
      return _isInit;
    } catch (e) {
      debugPrint('❌ Speech Init Failed: $e');
      return false;
    }
  }

  /// Starts a live recitation session for a specific Ayah
  Future<void> startLiveRecitation(int surah, int ayah) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return;

    if (!_isInit) await initialize();
    if (!_isInit) return;

    // 1. Fetch text and split into words
    final verse = await QuranDatabaseService().getVerse(surah, ayah);
    if (verse == null) return;

    final cleanText = QuranDatabaseService.removeTashkeel(verse['text']);
    _expectedWords = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _currentWordIndex = 0;
    _lastRecognizedText = "";

    // 2. Start Listening
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _handleSpeechResult(result.recognizedWords);
      },
      localeId: 'ar_SA',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _handleSpeechResult(String words) {
    if (words == _lastRecognizedText) return;
    _lastRecognizedText = words;

    final recognizedList = words.trim().split(RegExp(r'\s+'));
    if (recognizedList.isEmpty) return;

    // 🎯 Logic: Find the next expected word in the recognized text
    // We use a simple sequential matcher for high performance
    for (var spokenWord in recognizedList) {
      if (_currentWordIndex >= _expectedWords.length) break;

      final cleanSpoken = QuranDatabaseService.removeTashkeel(spokenWord);
      final targetWord = _expectedWords[_currentWordIndex];

      if (_isSimiliar(cleanSpoken, targetWord)) {
        _wordMatchController.add(_currentWordIndex);
        _currentWordIndex++;
        debugPrint('✅ Match: $targetWord');
      }
    }
  }

  bool _isSimiliar(String spoken, String target) {
    if (spoken == target) return true;
    // Basic fuzzy match: starts with or contains (for partial speech results)
    if (target.contains(spoken) && spoken.length > 2) return true;
    if (spoken.contains(target) && target.length > 2) return true;
    return false;
  }

  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  /// Deprecated: Static recognition (Keeping for compatibility)
  Future<RecognitionResult?> recognizeAyah() async {
    // Legacy implementation logic here if needed, otherwise removed for brevity
    return null;
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
