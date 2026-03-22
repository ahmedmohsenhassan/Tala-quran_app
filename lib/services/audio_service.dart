import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';

/// خدمة تشغيل الصوت للتلاوة
/// Audio playback service for Quran recitation
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  AudioService._internal() {
    _initSession();
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  // الحالة الحالية - Current state
  bool get isPlaying => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// تحميل وتشغيل ملف صوتي من رابط مع بيانات لوحة التحكم
  Future<void> playAudioWithMeta({
    required String url,
    required String id,
    required String title,
    required String artist,
    String? artUri,
  }) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: id,
          album: 'تلا القرآن',
          title: title,
          artist: artist,
          artUri: artUri != null ? Uri.parse(artUri) : null,
        ),
      );
      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  /// تحميل وتشغيل ملف صوتي من رابط
  /// Load and play audio from a URL
  Future<void> playFromUrl(String url) async {
    await playAudioWithMeta(
      url: url,
      id: url,
      title: 'تلاوة',
      artist: 'القارئ',
    );
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
