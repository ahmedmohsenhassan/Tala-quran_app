import 'package:flutter/material.dart';
import '../../widgets/mushaf_audio_player.dart';

/// 🎵 مشغل الصوت المدمج في أسفل المصحف
class MushafBottomPlayer extends StatelessWidget {
  final bool showBars;
  final Animation<double> slideAnimation;
  final String theme;
  final int pageNumber;
  final int? tappedAyah;
  final int? tappedSurah;
  final bool isAudioContinuing;
  final String? autoPlayReciter;

  // Callbacks
  final Function(int surah, int ayah) onAyahChanged;
  final Function(String? loc) onWordChanged;
  final Function(bool isBlurring) onMemorizationModeChanged;
  final VoidCallback onEndOfPage;
  final VoidCallback onClose;

  const MushafBottomPlayer({
    super.key,
    required this.showBars,
    required this.slideAnimation,
    required this.theme,
    required this.pageNumber,
    this.tappedAyah,
    this.tappedSurah,
    required this.isAudioContinuing,
    this.autoPlayReciter,
    required this.onAyahChanged,
    required this.onWordChanged,
    required this.onMemorizationModeChanged,
    required this.onEndOfPage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      key: const ValueKey('mushaf_audio_player_container'),
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 150 * (1 - slideAnimation.value)),
            child: IgnorePointer(
              ignoring: !showBars,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: showBars ? 1.0 : 0.0,
                child: child,
              ),
            ),
          );
        },
        child: MushafAudioPlayer(
          theme: theme,
          pageNumber: pageNumber,
          initialAyah: tappedAyah,
          initialSurah: tappedSurah,
          autoPlayContinues: isAudioContinuing || tappedAyah != null,
          autoPlayReciter: autoPlayReciter,
          onAyahChanged: onAyahChanged,
          onWordChanged: onWordChanged,
          onMemorizationModeChanged: onMemorizationModeChanged,
          onEndOfPage: onEndOfPage,
          onClose: onClose,
        ),
      ),
    );
  }
}
