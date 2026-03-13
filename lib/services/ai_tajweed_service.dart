import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class AITajweedService {
  static final AITajweedService _instance = AITajweedService._internal();
  factory AITajweedService() => _instance;
  AITajweedService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        _currentPath = '${directory.path}/tajweed_recitation.m4a';
        
        const config = RecordConfig();
        await _recorder.start(config, path: _currentPath!);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  Future<List<TajweedResult>> analyzeRecitation(String audioPath, int surah, int ayah) async {
    // Simulate AI analysis delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock results for demonstration
    // In a real scenario, this would call a Tarteel-like API or a custom ML model
    return [
      TajweedResult(
        word: "الحمد",
        status: TajweedStatus.correct,
        feedback: "نطق صحيح",
      ),
      TajweedResult(
        word: "لله",
        status: TajweedStatus.correct,
        feedback: "نطق صحيح",
      ),
      TajweedResult(
        word: "رب",
        status: TajweedStatus.warning,
        feedback: "انتبه لترقيق الراء",
      ),
      TajweedResult(
        word: "العالمين",
        status: TajweedStatus.correct,
        feedback: "مد عارض للسكون صحيح",
      ),
    ];
  }

  void dispose() {
    _recorder.dispose();
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
