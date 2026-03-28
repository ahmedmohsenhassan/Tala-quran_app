import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reciter_model.dart';
import '../models/ayah_playback_state.dart';
import '../utils/quran_page_helper.dart';
import 'audio_url_service.dart';

/// خدمة تشغيل الصوت للتلاوة — تدعم التشغيل الأوفلاين والعمل في الخلفية
/// Audio playback service for Quran recitation with offline & background support
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  
  AudioService._internal() {
    _initSession();
    _initListeners();
  }

  final AudioPlayer _player = AudioPlayer();
  static String? _localDirPath;

  // 📡 Playback Sequence State
  final StreamController<AyahPlaybackState?> _ayahStateController = 
      StreamController<AyahPlaybackState?>.broadcast();
  
  List<Map<String, int>> _playlist = [];
  int _currentIndex = -1;
  Reciter? _activeReciter;
  AyahPlaybackState? _lastEmittedState;
  
  // 📖 Hifz / Repetition State
  int _ayahRepeatCount = 1;      // How many times to repeat each Ayah
  int _rangeRepeatCount = 1;     // How many times to repeat the whole sequence
  int _currentAyahIteration = 1; // Current iteration of the active Ayah
  int _currentRangeIteration = 1;// Current iteration of the whole sequence
  int _rangeStartIndex = 0;      // Where the range begins
  
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;

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

  // --- GETTERS ---
  bool get isPlaying => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration? get duration => _player.duration;
  
  // 🎯 New: Stream for Ayah-by-Ayah synchronization
  Stream<AyahPlaybackState?> get ayahPlaybackStream => _ayahStateController.stream;
  AyahPlaybackState? get lastEmittedState => _lastEmittedState;

  // --- REPETITION SETTERS ---
  void setAyahRepeatCount(int count) {
    _ayahRepeatCount = count;
    _updateAyahState(); // Refresh UI
  }

  void setRangeRepeatCount(int count) {
    _rangeRepeatCount = count;
    _updateAyahState(); // Refresh UI
  }

  int get ayahRepeatCount => _ayahRepeatCount;
  int get rangeRepeatCount => _rangeRepeatCount;
  int get currentAyahIteration => _currentAyahIteration;
  int get currentRangeIteration => _currentRangeIteration;

  // ===================== LISTENERS =====================

  void _initListeners() {
    _stateSub = _player.playerStateStream.listen((state) {
      _updateAyahState();
      
      // Auto-transition to next ayah when current one finishes
      if (state.processingState == ProcessingState.completed) {
        if (_currentIndex != -1 && _playlist.isNotEmpty) {
           _handleAyahCompletion();
        }
      }
    });

    _posSub = _player.positionStream.listen((_) => _updateAyahState());
  }

  void _updateAyahState() {
    if (_currentIndex == -1 || _playlist.isEmpty) {
      _lastEmittedState = null;
      _ayahStateController.add(null);
      return;
    }

    final verse = _playlist[_currentIndex];
    final surah = verse['surah']!;
    final ayah = verse['ayah']!;
    final page = QuranPageHelper.getPageForAyah(surah, ayah);

    final state = AyahPlaybackState(
      surah: surah,
      ayah: ayah,
      page: page,
      processingState: _player.processingState,
      isPlaying: _player.playing,
      position: _player.position,
      duration: _player.duration,
      currentAyahIteration: _currentAyahIteration,
      totalAyahRepeats: _ayahRepeatCount,
      currentRangeIteration: _currentRangeIteration,
      totalRangeRepeats: _rangeRepeatCount,
    );

    // Only emit if something meaningful changed to avoid stream flooding
    if (_lastEmittedState?.surah != state.surah || 
        _lastEmittedState?.ayah != state.ayah ||
        _lastEmittedState?.isPlaying != state.isPlaying ||
        _lastEmittedState?.processingState != state.processingState) {
      _lastEmittedState = state;
      _ayahStateController.add(state);
    }
  }

  // ===================== AYAH SEQUENCES =====================

  Future<void> startAyahSequence({
    required List<Map<String, int>> verses,
    required int startIndex,
    required Reciter reciter,
    bool playImmediately = true,
  }) async {
    _playlist = verses;
    _currentIndex = startIndex;
    _rangeStartIndex = startIndex; // Track where we started
    _activeReciter = reciter;
    _currentAyahIteration = 1;
    _currentRangeIteration = 1;
    
    await _playCurrentFromPlaylist(playImmediately: playImmediately);
  }

  void _handleAyahCompletion() {
    // 1. Check Ayah Repetition
    if (_currentAyahIteration < _ayahRepeatCount || _ayahRepeatCount == 0) { // 0 = infinite
      _currentAyahIteration++;
      _player.seek(Duration.zero);
      _player.play();
      _updateAyahState();
    } else {
      // 2. Move to next Ayah
      _currentAyahIteration = 1;
      nextAyah();
    }
  }

  Future<void> _playCurrentFromPlaylist({bool playImmediately = true}) async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length || _activeReciter == null) return;
    
    final verse = _playlist[_currentIndex];
    final surah = verse['surah']!;
    final ayah = verse['ayah']!;
    final surahName = QuranPageHelper.surahNames[surah - 1];

    // 🚀 Prepare URLs (Smart Priority)
    final publicUrl = AudioUrlService.getAyahUrl(
      reciterBaseUrl: _activeReciter!.baseUrl,
      surahNumber: surah,
      ayahNumber: ayah,
    );
    
    String? firebaseFallback;
    if (_activeReciter!.firebasePath != null) {
      firebaseFallback = AudioUrlService.getFirebaseAyahUrl(
        firebasePath: _activeReciter!.firebasePath!,
        surahNumber: surah,
        ayahNumber: ayah,
      );
    }

    final List<String> sources = [];
    if (_activeReciter!.preferFirebase && firebaseFallback != null) {
      sources.add(firebaseFallback);
      sources.add(publicUrl);
    } else {
      sources.add(publicUrl);
      if (firebaseFallback != null) sources.add(firebaseFallback);
    }

    // 🛡️ Play with automatic fallback
    for (int i = 0; i < sources.length; i++) {
      try {
        final currentUrl = sources[i];
        debugPrint('🎧 [AudioService] Loading Source $i: $currentUrl');

        final audioSource = AudioSource.uri(
          Uri.parse(currentUrl),
          tag: MediaItem(
            id: 'ayah_${surah}_$ayah',
            album: 'تلا القرآن - سورة $surahName',
            title: 'آية $ayah',
            artist: _activeReciter!.name,
            artUri: Uri.parse(_activeReciter!.imageUrl),
          ),
        );

        await _player.setAudioSource(audioSource);
        if (playImmediately) {
          await _player.play();
        }
        _updateAyahState();
        return; // ✅ Success! Break the retry loop
      } catch (e) {
        debugPrint('❌ [AudioService] Source $i failed: $e');
        if (i == sources.length - 1) {
          debugPrint('🚩 [AudioService] ALL sources failed for $surah:$ayah');
        } else {
          debugPrint('🔄 [AudioService] Retrying with next source...');
        }
      }
    }
  }

  void nextAyah() {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _currentAyahIteration = 1;
      _playCurrentFromPlaylist(playImmediately: true);
    } else {
      // End of playlist reached — Check Range Repetition
      if (_currentRangeIteration < _rangeRepeatCount || _rangeRepeatCount == 0) {
        _currentRangeIteration++;
        _currentIndex = _rangeStartIndex; // Loop back to start of range
        _currentAyahIteration = 1;
        _playCurrentFromPlaylist(playImmediately: true);
        debugPrint('🔁 Range Looping: Iteration $_currentRangeIteration');
      } else {
        debugPrint('🏁 End of Ayah sequence reached');
      }
    }
  }

  void previousAyah() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _playCurrentFromPlaylist();
    }
  }

  // ===================== LEGACY & UTILS =====================

  /// تشغيل السورة (أوفلاين إذا كانت محملة، وإلا أونلاين)
  Future<void> playSurah({
    required Reciter reciter,
    required int surahNumber,
    required String surahName,
  }) async {
    _currentIndex = -1; // Reset sequence mode
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
  Future<void> stop() async {
    _currentIndex = -1;
    await _player.stop();
  }
  Future<void> seek(Duration position) async => await _player.seek(position);
  Future<void> dispose() async {
    _posSub?.cancel();
    _stateSub?.cancel();
    await _ayahStateController.close();
    await _player.dispose();
  }
}
