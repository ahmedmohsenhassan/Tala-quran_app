import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';

/// ويدجت مشغّل الصوت - يظهر أسفل شاشة السورة
/// Audio player widget - appears at the bottom of surah screen
class AudioPlayerWidget extends StatefulWidget {
  final String? audioUrl;
  final String surahName;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.surahName,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });

    _audioService.durationStream.listen((d) {
      if (mounted && d != null) {
        setState(() => _duration = d);
      }
    });

    _audioService.positionStream.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioUrl == null || widget.audioUrl!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.gold.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // شريط التقدم - Progress bar
          SliderTheme(
            data: SliderThemeData(
              thumbColor: AppColors.gold,
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.gold.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              min: 0,
              max:
                  _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              value: _position.inMilliseconds.toDouble().clamp(
                  0,
                  _duration.inMilliseconds
                      .toDouble()
                      .clamp(1, double.infinity)),
              onChanged: (value) {
                _audioService.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الوقت الحالي - Current time
              Text(
                _formatDuration(_position),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),

              // أزرار التحكم - Control buttons
              Row(
                children: [
                  // ترجيع 10 ثوانٍ - Rewind 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10,
                        color: AppColors.textSecondary),
                    iconSize: 28,
                    onPressed: () {
                      final newPos = _position - const Duration(seconds: 10);
                      _audioService.seek(
                          newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),

                  // تشغيل / إيقاف - Play / Pause
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.background,
                      ),
                      iconSize: 32,
                      onPressed: () {
                        if (_isPlaying) {
                          _audioService.pause();
                        } else if (_position > Duration.zero) {
                          _audioService.resume();
                        } else {
                          _audioService.playFromUrl(widget.audioUrl!);
                        }
                      },
                    ),
                  ),

                  // تقديم 10 ثوانٍ - Forward 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10,
                        color: AppColors.textSecondary),
                    iconSize: 28,
                    onPressed: () {
                      final newPos = _position + const Duration(seconds: 10);
                      _audioService
                          .seek(newPos > _duration ? _duration : newPos);
                    },
                  ),
                ],
              ),

              // المدة الكلية - Total duration
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
