import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';

/// ويدجت مشغّل الصوت الخاصة بصفحات المصحف
/// Audio player specific to the Mushaf page view
class MushafAudioPlayer extends StatefulWidget {
  final int pageNumber;
  final VoidCallback onClose;

  const MushafAudioPlayer({
    super.key,
    required this.pageNumber,
    required this.onClose,
  });

  @override
  State<MushafAudioPlayer> createState() => _MushafAudioPlayerState();
}

class _MushafAudioPlayerState extends State<MushafAudioPlayer> {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isError = false;

  @override
  void initState() {
    super.initState();

    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isError = state.processingState == ProcessingState.idle && !_isPlaying && _position == Duration.zero; // Simple error approximation for stream
        });
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

    // Start playing immediately when opened
    _playPageAudio();
  }

  // رابط تشغيل الصفحة (مؤقتاً للشيخ الحصري من everyayah)
  // Page audio URL (temporarily Al-Husary)
  String _getPageAudioUrl(int page) {
    final paddedPage = page.toString().padLeft(3, '0');
    // Using a reliable open source audio API for pages (e.g. mp3quran or everyayah)
    // Note: most APIs only provide per-ayah, per-surah, or per-juz. 
    // For per-page, some specific APIs exist. Using a placeholder for demonstration:
    return 'https://equran.me/audio/1/$paddedPage.mp3'; // Example format, may need adjustment based on active APIs
  }

  Future<void> _playPageAudio() async {
    setState(() => _isError = false);
    await _audioService.playFromUrl(_getPageAudioUrl(widget.pageNumber));
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.gold.withOpacity(0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تلاوة الصفحة ${widget.pageNumber}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: widget.onClose,
              ),
            ],
          ),
          
          if (_isError)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'عذراً، فشل تحميل الصوت.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            )
          else ...[
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
                max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                value: _position.inMilliseconds
                    .toDouble()
                    .clamp(0, _duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                onChanged: (value) {
                  _audioService.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: AppColors.textSecondary),
                      iconSize: 24,
                      onPressed: () {
                        final newPos = _position - const Duration(seconds: 10);
                        _audioService.seek(newPos < Duration.zero ? Duration.zero : newPos);
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
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
                            _playPageAudio();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: AppColors.textSecondary),
                      iconSize: 24,
                      onPressed: () {
                        final newPos = _position + const Duration(seconds: 10);
                        _audioService.seek(newPos > _duration ? _duration : newPos);
                      },
                    ),
                  ],
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
