import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reciter_model.dart';
import 'audio_url_service.dart';

/// خدمة تشغيل الصوت للتلاوة — تدعم التشغيل الأوفلاين
/// Audio playback service for Quran recitation with offline support
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  AudioService._internal() {
    _initSession();
  }

  final AudioPlayer _player = AudioPlayer();
  static String? _localDirPath;

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  static Future<String> _getLocalPath() async {
    if (_localDirPath != null) return _localDirPath!;
    final dir = await getApplicationDocumentsDirectory();
    _localDirPath = dir.path;
    return _localDirPath!;
  }

  /// الحصول على مسار ملف السورة محلياً
  static Future<File> getSurahFile(String reciterId, int surahNumber) async {
    final base = await _getLocalPath();
    final s = surahNumber.toString().padLeft(3, '0');
    return File('$base/audio/$reciterId/$s.mp3');
  }

  /// التأكد من وجود السورة محلياً
  Future<bool> isSurahDownloaded(String reciterId, int surahNumber) async {
    final file = await getSurahFile(reciterId, surahNumber);
    return await file.exists();
  }

  // الحالة الحالية - Current state
  bool get isPlaying => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// تشغيل السورة (أوفلاين إذا كانت محملة، وإلا أونلاين)
  Future<void> playSurah({
    required Reciter reciter,
    required int surahNumber,
    required String surahName,
  }) async {
    final localFile = await getSurahFile(reciter.id, surahNumber);
    final bool isOffline = await localFile.exists();
    
    final String url = isOffline 
        ? localFile.path 
        : AudioUrlService.getSurahUrl(reciter: reciter, surahNumber: surahNumber);

    try {
      final audioSource = isOffline
          ? AudioSource.file(
              url,
              tag: MediaItem(
                id: 'surah_$surahNumber',
                album: 'تلا القرآن (أوفلاين)',
                title: 'سورة $surahName',
                artist: reciter.name,
                artUri: Uri.parse(reciter.imageUrl),
              ),
            )
          : AudioSource.uri(
              Uri.parse(url),
              tag: MediaItem(
                id: 'surah_$surahNumber',
                album: 'تلا القرآن',
                title: 'سورة $surahName',
                artist: reciter.name,
                artUri: Uri.parse(reciter.imageUrl),
              ),
            );

      await _player.setAudioSource(audioSource);
      await _player.play();
    } catch (e) {
      debugPrint('❌ [AudioService] Playback error: $e');
    }
  }

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
  Future<void> playFromUrl(String url) async {
    await playAudioWithMeta(
      url: url,
      id: url,
      title: 'تلاوة',
      artist: 'القارئ',
    );
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> dispose() async => await _player.dispose();
}
