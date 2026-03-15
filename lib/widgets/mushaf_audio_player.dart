import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../services/audio_url_service.dart';
import '../utils/app_colors.dart';
import '../models/reciter_model.dart';
import '../services/ayah_sync_service.dart';
import '../utils/quran_page_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ويدجت مشغّل الصوت الخاصة بصفحات المصحف
/// Audio player specific to the Mushaf page view
class MushafAudioPlayer extends StatefulWidget {
  final int pageNumber;
  final Function(int surah, int ayah) onAyahChanged;
  final ValueChanged<bool>? onMemorizationModeChanged;
  final VoidCallback onClose;

  const MushafAudioPlayer({
    super.key,
    required this.pageNumber,
    required this.onAyahChanged,
    this.onMemorizationModeChanged,
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
  Reciter? _selectedReciter;
  List<Map<String, dynamic>> _verseTimings = [];
  int _currentAyah = -1;
  int _currentSurah = -1;

  bool _isMemorizationMode = false;
  int? _loopStartAyah;
  int? _loopEndAyah;

  // Stream Subscriptions
  StreamSubscription? _playerStateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();

    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isError = state.processingState == ProcessingState.idle &&
              !_isPlaying &&
              _position ==
                  Duration.zero; // Simple error approximation for stream
        });
      }
    });

    _durationSub = _audioService.durationStream.listen((d) {
      if (mounted && d != null) {
        setState(() => _duration = d);
      }
    });

    _positionSub = _audioService.positionStream.listen((p) {
      if (mounted) {
        setState(() => _position = p);
        _updateCurrentAyah(p);
      }
    });

    // Start playing immediately when opened
    _initAndPlay();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    
    // Safely stop audio without awaiting to avoid blocking the disposal phase
    _audioService.stop().catchError((e) {
      debugPrint('Error stopping audio in dispose: $e');
    });
    
    super.dispose();
  }

  Future<void> _initAndPlay() async {
    final prefs = await SharedPreferences.getInstance();
    final reciterId = prefs.getString('selected_reciter_id') ?? 'al_afasy';
    if (mounted) {
      setState(() {
        _selectedReciter =
            Reciter.defaultReciters.firstWhere((r) => r.id == reciterId);
      });
    }
    _playPageAudio();
  }

  // رابط تشغيل الصفحة باستخدام الخدمة الديناميكية
  // Page audio URL using dynamic service
  String _getPageAudioUrl(int page) {
    if (_selectedReciter == null) {
      // Fallback if not loaded yet
      return 'https://server13.mp3quran.net/husr/${page.toString().padLeft(3, '0')}.mp3';
    }

    return AudioUrlService.getPageUrl(
      reciter: _selectedReciter!,
      pageNumber: page,
    );
  }

  Future<void> _playPageAudio() async {
    if (_isError) setState(() => _isError = false);
    final url = _getPageAudioUrl(widget.pageNumber);
    debugPrint('Playing page audio: $url');
    
    // Load timings if we have a reciter
    if (_selectedReciter != null) {
      final surah = QuranPageHelper.getSurahForPage(widget.pageNumber);
      _currentSurah = surah;
      _verseTimings = await AyahSyncService().getVerseTimings(
        surahNumber: surah,
        reciter: _selectedReciter!,
      );
    }
    
    await _audioService.playFromUrl(url);
  }

  @override
  void didUpdateWidget(covariant MushafAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      // Automatic switch on page turn
      _playPageAudio();
    }
  }

  void _updateCurrentAyah(Duration p) {
    if (_verseTimings.isEmpty) return;

    final ms = p.inMilliseconds;
    for (var timing in _verseTimings) {
      if (ms >= timing['timestampFrom'] && ms <= timing['timestampTo']) {
        if (_currentAyah != timing['ayahNumber']) {
          setState(() => _currentAyah = timing['ayahNumber']);
          widget.onAyahChanged(_currentSurah, _currentAyah);
        }
        break;
      }
    }

    // A-B Loop Logic Check (independently check if we crossed the end boundary)
    if (_loopStartAyah != null && _loopEndAyah != null) {
      try {
        final endTiming = _verseTimings.firstWhere((t) => t['ayahNumber'] == _loopEndAyah);
        if (ms >= endTiming['timestampTo'] - 200) { // 200ms buffer before it switches to next
          _seekToAyah(_loopStartAyah!);
        }
      } catch (e) {
        // Ignored if not found
      }
    }
  }

  void _seekToAyah(int ayahNumber) {
    try {
      final timing = _verseTimings.firstWhere((t) => t['ayahNumber'] == ayahNumber);
      _audioService.seek(Duration(milliseconds: timing['timestampFrom']));
    } catch (e) {
      debugPrint('Ayah timing not found for $ayahNumber: $e');
    }
  }

  void _showABLoopDialog() {
    if (_verseTimings.isEmpty) return;
    
    int tempStart = _loopStartAyah ?? _verseTimings.first['ayahNumber'];
    int tempEnd = _loopEndAyah ?? _verseTimings.last['ayahNumber'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: AppColors.background,
                title: const Text(
                  'تكرار الآيات (A-B Loop)',
                  style: TextStyle(color: AppColors.gold, fontFamily: 'Amiri', fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Text('من آية', style: TextStyle(color: Colors.white, fontFamily: 'Amiri')),
                            DropdownButton<int>(
                              value: tempStart,
                              dropdownColor: AppColors.cardBackground,
                              style: const TextStyle(color: AppColors.gold, fontFamily: 'Amiri'),
                              items: _verseTimings.map((t) {
                                return DropdownMenuItem<int>(
                                  value: t['ayahNumber'],
                                  child: Text(t['ayahNumber'].toString()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    tempStart = val;
                                    if (tempEnd < tempStart) tempEnd = tempStart;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('إلى آية', style: TextStyle(color: Colors.white, fontFamily: 'Amiri')),
                            DropdownButton<int>(
                              value: tempEnd,
                              dropdownColor: AppColors.cardBackground,
                              style: const TextStyle(color: AppColors.gold, fontFamily: 'Amiri'),
                              items: _verseTimings.map((t) {
                                return DropdownMenuItem<int>(
                                  value: t['ayahNumber'],
                                  child: Text(t['ayahNumber'].toString()),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    tempEnd = val;
                                    if (tempStart > tempEnd) tempStart = tempEnd;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loopStartAyah = null;
                        _loopEndAyah = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('إلغاء التكرار', style: TextStyle(color: Colors.redAccent, fontFamily: 'Amiri')),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _loopStartAyah = tempStart;
                        _loopEndAyah = tempEnd;
                      });
                      _seekToAyah(tempStart);
                      if (!_isPlaying) _playPageAudio();
                      Navigator.pop(context);
                    },
                    child: const Text('تطبيق', style: TextStyle(color: AppColors.gold, fontFamily: 'Amiri')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
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
            // أدوات الحفظ (A-B Loop و التظليل)
            if (_verseTimings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text Blur Toggle
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isMemorizationMode = !_isMemorizationMode;
                        });
                        widget.onMemorizationModeChanged?.call(_isMemorizationMode);
                      },
                      child: Row(
                        children: [
                          Icon(
                            _isMemorizationMode ? Icons.visibility_off : Icons.visibility,
                            color: _isMemorizationMode ? AppColors.gold : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'إخفاء النص',
                            style: TextStyle(
                              color: _isMemorizationMode ? AppColors.gold : Colors.grey,
                              fontSize: 12,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // A-B Loop Dialog Button
                    InkWell(
                      onTap: () => _showABLoopDialog(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            color: (_loopStartAyah != null && _loopEndAyah != null)
                                ? AppColors.gold
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_loopStartAyah != null && _loopEndAyah != null)
                                ? 'تكرار: $_loopStartAyah-$_loopEndAyah'
                                : 'تكرار الآيات',
                            style: TextStyle(
                              color: (_loopStartAyah != null && _loopEndAyah != null)
                                  ? AppColors.gold
                                  : Colors.grey,
                              fontSize: 12,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            SliderTheme(
              data: SliderThemeData(
                thumbColor: AppColors.gold,
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 3,
              ),
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds
                    .toDouble()
                    .clamp(1, double.infinity),
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
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10,
                          color: AppColors.textSecondary),
                      iconSize: 24,
                      onPressed: () {
                        final newPos = _position - const Duration(seconds: 10);
                        _audioService.seek(
                            newPos < Duration.zero ? Duration.zero : newPos);
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
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
                      icon: const Icon(Icons.forward_10,
                          color: AppColors.textSecondary),
                      iconSize: 24,
                      onPressed: () {
                        final newPos = _position + const Duration(seconds: 10);
                        _audioService
                            .seek(newPos > _duration ? _duration : newPos);
                      },
                    ),
                  ],
                ),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
