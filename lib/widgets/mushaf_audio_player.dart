import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_service.dart';
import '../services/audio_url_service.dart';
import '../utils/app_colors.dart';
import '../models/reciter_model.dart';
import '../services/ayah_sync_service.dart';
import '../utils/quran_page_helper.dart';
import '../services/recitation_sync_service.dart'; // 🎙️ New for Phase 64
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ويدجت مشغّل الصوت الخاصة بصفحات المصحف
/// Audio player specific to the Mushaf page view
class MushafAudioPlayer extends StatefulWidget {
  final int pageNumber;
  final int? initialAyah;
  final Function(int surah, int ayah) onAyahChanged;
  final Function(String? location)? onWordChanged; // 🎯 New for word highlighting
  final ValueChanged<bool>? onMemorizationModeChanged;
  final VoidCallback? onEndOfPage; // 🔄 Continuous Auto-Scroll
  final VoidCallback onClose;

  const MushafAudioPlayer({
    super.key,
    required this.pageNumber,
    this.initialAyah,
    required this.onAyahChanged,
    this.onWordChanged,
    this.onMemorizationModeChanged,
    this.onEndOfPage,
    required this.onClose,
  });

  @override
  State<MushafAudioPlayer> createState() => _MushafAudioPlayerState();
}

class _MushafAudioPlayerState extends State<MushafAudioPlayer> {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  Reciter? _selectedReciter;
  
  // New State for Ayah-by-Ayah
  int _currentAyahIndex = 0;
  List<Map<String, int>> _pageVerses = []; // List of {surah, ayah} on this page
  int _currentAyah = -1;
  int _currentSurah = -1;

  bool _isMemorizationMode = false;
  bool _isLooping = false; // New: Repeat current Ayah

  // Stream Subscriptions
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub; // 🎯 High-frequency sync
  
  // Word sync data
  final RecitationSyncService _syncService = RecitationSyncService();
  List<Map<String, dynamic>> _currentAyahSegments = [];

  @override
  void initState() {
    super.initState();

    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });

        // الانتقال التلقائي للآية التالية أو التكرار عند انتهاء الحالية
        // Auto-transition to next ayah or loop when current one finishes
        if (state.processingState == ProcessingState.completed) {
          if (_isLooping) {
            _playCurrentAyah();
          } else {
            _playNextAyah();
          }
        }
        
        // Clear word highlight if paused or stopped
        if (!state.playing && widget.onWordChanged != null) {
           widget.onWordChanged!(null);
        }
      }
    });

    // 🎯 Listen to audio position for word sync
    _positionSub = _audioService.positionStream.listen((pos) {
      if (_currentAyahSegments.isNotEmpty && widget.onWordChanged != null) {
        final wordIdx = _syncService.findActiveWordIndex(pos.inMilliseconds, _currentAyahSegments);
        if (wordIdx != null) {
          final location = '$_currentSurah:$_currentAyah:$wordIdx';
          widget.onWordChanged!(location);
        }
      }
    });

    _initPlayer();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel(); // 🎯 Stop sync listener
    _audioService.stop().catchError((e) => debugPrint('Error stopping: $e'));
    super.dispose();
  }

  Future<void> _initPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final reciterId = prefs.getString('selected_reciter_id') ?? 'al_afasy';
    
    // Get verses on this page
    final coords = await AyahSyncService().getPageCoordinates(widget.pageNumber);
    final Set<String> uniqueVerses = {};
    final List<Map<String, int>> verses = [];
    
    for (var c in coords) {
      final key = '${c.surahNumber}:${c.ayahNumber}';
      if (!uniqueVerses.contains(key)) {
        uniqueVerses.add(key);
        verses.add({'surah': c.surahNumber, 'ayah': c.ayahNumber});
      }
    }

    if (mounted) {
      setState(() {
        _selectedReciter = Reciter.defaultReciters.firstWhere((r) => r.id == reciterId);
        _pageVerses = verses;
        if (_pageVerses.isNotEmpty) {
          // If initialAyah is provided, find its index
          if (widget.initialAyah != null) {
            final idx = _pageVerses.indexWhere((v) => v['ayah'] == widget.initialAyah);
            _currentAyahIndex = idx != -1 ? idx : 0;
          } else {
            _currentAyahIndex = 0;
          }
          
          _currentSurah = _pageVerses[_currentAyahIndex]['surah']!;
          _currentAyah = _pageVerses[_currentAyahIndex]['ayah']!;
        }
      });
      _playCurrentAyah();
    }
  }

  Future<void> _playCurrentAyah() async {
    if (_selectedReciter == null || _pageVerses.isEmpty) return;
    
    final surah = _pageVerses[_currentAyahIndex]['surah']!;
    final ayah = _pageVerses[_currentAyahIndex]['ayah']!;
    
    setState(() {
      _currentSurah = surah;
      _currentAyah = ayah;
    });

    final url = AudioUrlService.getAyahUrl(
      reciterBaseUrl: _selectedReciter!.baseUrl,
      surahNumber: surah,
      ayahNumber: ayah,
    );

    widget.onAyahChanged(surah, ayah);
    
    // 🎯 Fetch timestamps for the new Ayah (Phase 64)
    if (_selectedReciter != null) {
       _syncService.getVerseTimestamps(7, '$surah:$ayah').then((segments) {
         if (mounted) setState(() => _currentAyahSegments = segments);
       });
    }

    final surahName = QuranPageHelper.surahNames[surah - 1];
    await _audioService.playAudioWithMeta(
      url: url,
      id: '$surah:$ayah',
      title: 'سورة $surahName - آية $ayah',
      artist: _selectedReciter!.name,
    );
  }

  void _playNextAyah() {
    if (_currentAyahIndex < _pageVerses.length - 1) {
      setState(() => _currentAyahIndex++);
      _playCurrentAyah();
    } else {
      // End of page - clear highlight and trigger auto-scroll if provided
      if (widget.onWordChanged != null) widget.onWordChanged!(null);
      if (widget.onEndOfPage != null) {
        widget.onEndOfPage!();
      } else {
        setState(() => _isPlaying = false);
      }
    }
  }

  void _playPreviousAyah() {
    if (_currentAyahIndex > 0) {
      setState(() => _currentAyahIndex--);
      _playCurrentAyah();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasNext = _currentAyahIndex < _pageVerses.length - 1;
    final bool hasPrev = _currentAyahIndex > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // المقبض العلوي
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentSurah > 0 
                      ? 'سورة ${QuranPageHelper.surahNames[_currentSurah - 1]} - آية $_currentAyah'
                      : 'تلاوة الآية $_currentAyah',
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'صفحة ${widget.pageNumber}',
                    style: GoogleFonts.amiri(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: widget.onClose,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // أدوات التحكم الرئيسية
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الآية السابقة
              _buildNavButton(
                icon: Icons.skip_next_rounded, // RTL: Next is previous in flow
                enabled: hasNext,
                onTap: _playNextAyah,
              ),
              
              const SizedBox(width: 24),
              
              // زر التشغيل المركزي
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.background,
                    size: 40,
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _audioService.pause();
                    } else {
                      _audioService.resume();
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 24),
              
              // الآية التالية
              _buildNavButton(
                icon: Icons.skip_previous_rounded, // RTL: Prev is next in flow
                enabled: hasPrev,
                onTap: _playPreviousAyah,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // التحكم في الوضع (حفظ / إخفاء)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeToggle(
                icon: _isMemorizationMode ? Icons.visibility_off : Icons.visibility,
                label: 'إخفاء النص',
                active: _isMemorizationMode,
                onTap: () {
                  setState(() => _isMemorizationMode = !_isMemorizationMode);
                  widget.onMemorizationModeChanged?.call(_isMemorizationMode);
                },
              ),
              
              // تكرار الآيات
              _buildModeToggle(
                icon: _isLooping ? Icons.repeat_one_on_rounded : Icons.repeat_one_rounded,
                label: 'تكرار الآية',
                active: _isLooping,
                onTap: () {
                  setState(() => _isLooping = !_isLooping);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: enabled ? AppColors.gold.withValues(alpha: 0.2) : Colors.white10,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.gold : Colors.white24,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildModeToggle({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: active ? AppColors.gold : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.amiri(
              color: active ? AppColors.gold : AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
