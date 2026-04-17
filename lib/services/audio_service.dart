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
  
  int _currentIndex = -1;
  AyahPlaybackState? _lastEmittedState;
  
  // 📖 Hifz / Repetition State
  int _ayahRepeatCount = 1;      // How many times to repeat each Ayah
  int _rangeRepeatCount = 1;     // How many times to repeat the whole sequence
  int _currentAyahIteration = 1; // Current iteration of the active Ayah
  int _currentRangeIteration = 1;// Current iteration of the whole sequence
  
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  bool _sequenceComplete = false;
  ConcatenatingAudioSource? _playlist;

  bool get isSequenceComplete => _sequenceComplete;

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidWillPauseWhenDucked: true,
      avAudioSessionCategory: AVAudioSessionCategory.playback,
    ));
    
    // 🎧 Intercept audio interruptions (Calls, other apps)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _player.pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            _player.play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
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
        if (_currentIndex != -1 && _player.sequence != null) {
           _handleAyahCompletion();
        }
      }
    });

    _posSub = _player.positionStream.listen((_) => _updateAyahState());

    // 📡 Monitor index changes for notification sync
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        _currentAyahIteration = 1; // Reset iteration on manual/auto skip
        _updateAyahState();
      }
    });
  }

  void _updateAyahState() {
    final mediaItem = _player.sequenceState?.currentSource?.tag as MediaItem?;
    
    if (mediaItem == null || _currentIndex == -1) {
      _lastEmittedState = null;
      _ayahStateController.add(null);
      return;
    }

    final int surah = mediaItem.extras?['surah'] ?? 0;
    final int ayah = mediaItem.extras?['ayah'] ?? 0;
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

    _lastEmittedState = state;
    _ayahStateController.add(state);
  }

  /// 🧹 RESET SYNCHRONOUSLY: Clears completion flags instantly to prevent double-page jumps.
  /// Should be called by the UI as soon as a page change is detected.
  void clearSequenceStatus() {
    _sequenceComplete = false;
    _lastEmittedState = null;
    _ayahStateController.add(null);
  }

  // ===================== AYAH SEQUENCES =====================

  Future<void> startAyahSequence({
    required List<Map<String, int>> verses,
    required int startIndex,
    required Reciter reciter,
    bool playImmediately = true,
  }) async {
    // 🛑 PROACTIVE STOP: Prevent old audio from leaking during the transition
    await _player.stop(); 
    
    // 🧹 STATE RESET: Notify listeners immediately that the old sequence is gone
    _lastEmittedState = null;
    _ayahStateController.add(null);

    _currentIndex = startIndex;
    _currentAyahIteration = 1;
    _currentRangeIteration = 1;
    _sequenceComplete = false;
    
    // 🚀 Build the ConcatenatingAudioSource efficiently
    final List<AudioSource> audioSources = verses.map((v) => 
      _createAudioSource(v['surah']!, v['ayah']!, reciter)
    ).toList();

    _playlist = ConcatenatingAudioSource(
      children: audioSources, 
      useLazyPreparation: true,
    );
    
    await _player.setAudioSource(_playlist!, initialIndex: startIndex);
    
    // ♾️ Set to LoopMode.off by default because we handle chaining manually
    // or LoopMode.all if we want to loop the current sequence.
    // For Quran, we'll use LoopMode.off and handle the "Next Surah" or "Wrap Al-Fatihah" logic.
    await _player.setLoopMode(LoopMode.off);

    if (playImmediately) {
      Future.delayed(const Duration(milliseconds: 100), () => _player.play());
    }
  }

  /// ➕ Dynamic Append: Add more verses to the existing playlist without stopping playback
  Future<void> appendVerses({
    required List<Map<String, int>> verses,
    required Reciter reciter,
  }) async {
    if (_playlist == null) return;

    final List<AudioSource> newSources = verses.map((v) => 
      _createAudioSource(v['surah']!, v['ayah']!, reciter)
    ).toList();

    await _playlist!.addAll(newSources);
    debugPrint('➕ [AudioService] Appended ${newSources.length} verses to playlist. New size: ${_playlist!.length}');
  }

  AudioSource _createAudioSource(int surah, int ayah, Reciter reciter) {
    final surahName = QuranPageHelper.surahNames[surah - 1];
    final publicUrl = AudioUrlService.getAyahUrl(
      reciterBaseUrl: reciter.baseUrl,
      surahNumber: surah,
      ayahNumber: ayah,
    );

    String? firebaseFallback;
    if (reciter.firebasePath != null) {
      firebaseFallback = AudioUrlService.getFirebaseAyahUrl(
        firebasePath: reciter.firebasePath!,
        surahNumber: surah,
        ayahNumber: ayah,
      );
    }

    // Determine primary source
    final String primaryUrl = (reciter.preferFirebase && firebaseFallback != null) 
        ? firebaseFallback 
        : publicUrl;

    return AudioSource.uri(
      Uri.parse(primaryUrl),
      tag: MediaItem(
        id: 'ayah_${surah}_$ayah',
        album: 'سورة $surahName',
        title: 'آية $ayah',
        artist: reciter.name,
        artUri: Uri.parse(reciter.imageUrl),
        extras: {'surah': surah, 'ayah': ayah},
      ),
    );
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

  void nextAyah() {
    if (_player.hasNext) {
      _currentAyahIteration = 1;
      _player.seekToNext();
      _sequenceComplete = false;
    } else {
      // 🔄 Infinite Wrap-around: Go back to the very first ayah of the Quran
      debugPrint('🔁 [AudioService] Quran complete. Looping back to Al-Fatihah.');
      _currentAyahIteration = 1;
      _player.seek(Duration.zero, index: 0);
      _sequenceComplete = false;
      _updateAyahState();
    }
  }

  void previousAyah() {
    if (_player.hasPrevious) {
      _currentAyahIteration = 1;
      _player.seekToPrevious();
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
