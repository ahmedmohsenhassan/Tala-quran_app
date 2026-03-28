import 'package:just_audio/just_audio.dart';

/// حالة تشغيل الآية الحالية — Current Ayah playback state
class AyahPlaybackState {
  final int surah;
  final int ayah;
  final int page;
  final String? wordLocation; // "surah:ayah:wordIndex"
  final ProcessingState processingState;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  final int currentAyahIteration;
  final int totalAyahRepeats;
  final int currentRangeIteration;
  final int totalRangeRepeats;

  AyahPlaybackState({
    required this.surah,
    required this.ayah,
    required this.page,
    this.wordLocation,
    required this.processingState,
    required this.isPlaying,
    this.position = Duration.zero,
    this.duration,
    this.currentAyahIteration = 1,
    this.totalAyahRepeats = 1,
    this.currentRangeIteration = 1,
    this.totalRangeRepeats = 1,
  });

  bool get isCompleted => processingState == ProcessingState.completed;

  AyahPlaybackState copyWith({
    int? surah,
    int? ayah,
    int? page,
    String? wordLocation,
    ProcessingState? processingState,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return AyahPlaybackState(
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      page: page ?? this.page,
      wordLocation: wordLocation ?? this.wordLocation,
      processingState: processingState ?? this.processingState,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}
