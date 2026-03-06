import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// خدمة تشغيل الصوت للتلاوة
/// Audio playback service for Quran recitation
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  // الحالة الحالية - Current state
  bool get isPlaying => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// تحميل وتشغيل ملف صوتي من رابط
  /// Load and play audio from a URL
  Future<void> playFromUrl(String url) async {
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      // تجاهل الأخطاء - Silently handle errors
      debugPrint('Audio error: $e');
    }
  }

  /// إيقاف مؤقت
  /// Pause playback
  Future<void> pause() async {
    await _player.pause();
  }

  /// استئناف التشغيل
  /// Resume playback
  Future<void> resume() async {
    await _player.play();
  }

  /// إيقاف كامل
  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
  }

  /// تقديم / ترجيع
  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// التخلص من الموارد
  /// Dispose resources
  Future<void> dispose() async {
    await _player.dispose();
  }
}
