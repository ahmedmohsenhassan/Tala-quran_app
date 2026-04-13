import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';
import '../models/reciter_model.dart';
import '../utils/quran_page_helper.dart';
import '../services/recitation_sync_service.dart'; // 🎙️ New for Phase 64
import '../services/quran_text_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ويدجت مشغّل الصوت الخاصة بصفحات المصحف — الآن مرتبطة بخدمة عالمية
/// Audio player specific to the Mushaf page view — now linked to global service
class MushafAudioPlayer extends StatefulWidget {
  final int pageNumber;
  final int? initialAyah;
  final int? initialSurah;
  final Function(int surah, int ayah) onAyahChanged;
  final Function(String? location)? onWordChanged; // 🎯 New for word highlighting
  final ValueChanged<bool>? onMemorizationModeChanged;
  final VoidCallback? onEndOfPage; // 🔄 Continuous Auto-Scroll
  final bool autoPlayContinues; // 🚀 New: for seamless transitions
  final String? autoPlayReciter; // 🌅 New for AOTD
  final String theme;
  final VoidCallback onClose;

  const MushafAudioPlayer({
    super.key,
    required this.pageNumber,
    this.initialAyah,
    this.initialSurah,
    required this.onAyahChanged,
    this.onWordChanged,
    this.onMemorizationModeChanged,
    this.onEndOfPage,
    this.autoPlayContinues = false,
    this.autoPlayReciter,
    required this.onClose,
    required this.theme,
  });

  @override
  State<MushafAudioPlayer> createState() => _MushafAudioPlayerState();
}

class _MushafAudioPlayerState extends State<MushafAudioPlayer> {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  Reciter? _selectedReciter;
  
  // Data for the current page
  List<Map<String, int>> _pageVerses = []; 
  int _currentAyah = -1;
  int _currentSurah = -1;

  // Stream Subscriptions
  StreamSubscription? _ayahPlaybackSub;
  
  // Word sync data
  final RecitationSyncService _syncService = RecitationSyncService();
  List<Map<String, dynamic>> _currentAyahSegments = [];
  bool _isPageTurnTriggered = false;

  // 📖 Repetition State
  int _currentAyahIteration = 1;
  int _ayahRepeatCount = 1;
  int _currentRangeIteration = 1;
  int _rangeRepeatCount = 1;

  Color get _deepGreen {
    switch (widget.theme) {
      case ThemeService.mushafPremium: return const Color(0xFF33270F);
      case ThemeService.mushafDark: return const Color(0xFF05110E);
      default: return const Color(0xFF031E17);
    }
  }

  Color get _richGold {
    switch (widget.theme) {
      case ThemeService.mushafDark: return const Color(0xFFD4A947).withValues(alpha: 0.6);
      default: return const Color(0xFFD4A947);
    }
  }

  @override
  void initState() {
    super.initState();

    _ayahPlaybackSub = _audioService.ayahPlaybackStream.listen((state) {
      if (!mounted) return;
      
      if (state == null) {
        setState(() => _isPlaying = false);
        return;
      }

      setState(() {
        _isPlaying = state.isPlaying;
        _currentAyahIteration = state.currentAyahIteration;
        _ayahRepeatCount = state.totalAyahRepeats;
        _currentRangeIteration = state.currentRangeIteration;
        _rangeRepeatCount = state.totalRangeRepeats;
        
        if (_currentSurah != state.surah || _currentAyah != state.ayah) {
          _currentSurah = state.surah;
          _currentAyah = state.ayah;
          // 🎯 Clear old segments before fetching new ones so we don't accidentally use wrong timings!
          _currentAyahSegments = [];
          
          // 🎯 Fetch timestamps for the new Ayah
          _syncService.getVerseTimestamps(7, '$_currentSurah:$_currentAyah').then((segments) {
             if (mounted) setState(() => _currentAyahSegments = segments);
          });
          
          // 📢 Notify parent ONLY when the Ayah actually changes (fixes word highlight clearing bug)
          widget.onAyahChanged(state.surah, state.ayah);
        }
      });

      // 🏁 Handle Sequence Completion → trigger page turn ONE time
      if (_audioService.isSequenceComplete && widget.onEndOfPage != null) {
        if (!_isPageTurnTriggered) {
          _isPageTurnTriggered = true;
          debugPrint('🏁 [MushafAudioPlayer] Sequence complete on page ${widget.pageNumber}. Triggering page turn.');
          widget.onEndOfPage!();
        }
        return; // Don't process further until new page loads
      }

      // Handle Word Synchronization
      if (state.isPlaying) {
        _syncWords(state.position);
      }
    });

    // Initial load without auto-play unless an initialAyah is provided or autoPlay is active
    _initPlayer(playAfterLoad: widget.initialAyah != null || widget.autoPlayContinues);
  }

  void _syncWords(Duration pos) {
    if (_currentAyahSegments.isNotEmpty && widget.onWordChanged != null) {
      final wordIdx = _syncService.findActiveWordIndex(pos.inMilliseconds, _currentAyahSegments);
      if (wordIdx != null) {
        final location = '$_currentSurah:$_currentAyah:$wordIdx';
        widget.onWordChanged!(location);
      }
    }
  }

  @override
  void didUpdateWidget(MushafAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.pageNumber != widget.pageNumber) {
      debugPrint('📄 [MushafAudioPlayer] UI Page Moved: ${oldWidget.pageNumber} -> ${widget.pageNumber}');
      _isPageTurnTriggered = false; // 🔄 Reset the one-off trigger for the new page
      
      // 🚀 IF it was an auto-advance (seamless transition), skip _initPlayer
      // BUT if it was a manual swipe, we MUST restart to synchronize.
      final currentState = _audioService.lastEmittedState;
      bool isAlreadyOnNewPage = currentState != null && currentState.page == widget.pageNumber;
      
      if (widget.autoPlayContinues && isAlreadyOnNewPage && _audioService.isPlaying) {
        debugPrint('🚀 [MushafAudioPlayer] Seamless transition. Maintaining current flow.');
        _loadPageData(); // Just refresh background verses
        return;
      }

      // Restart sequence for manual page jumps OR if audio was playing and we moved manually
      bool shouldPlay = _audioService.isPlaying || widget.autoPlayContinues;
      _initPlayer(playAfterLoad: shouldPlay);
    } 
    // 🎯 If a specific Ayah was tapped (new initialAyah)
    else if (widget.initialAyah != null && widget.initialAyah != oldWidget.initialAyah) {
      debugPrint('🎯 Ayah Tapped: ${widget.initialSurah}:${widget.initialAyah}');
      _initPlayer(playAfterLoad: true);
    }
    // 🚀 If auto-play was just enabled (e.g. from a seamless page transition where the widget was preloaded)
    else if (widget.autoPlayContinues && !oldWidget.autoPlayContinues) {
      debugPrint('🚀 Auto-play enabled via transition on page ${widget.pageNumber}');
      _initPlayer(playAfterLoad: true);
    }
  }


  @override
  void dispose() {
    _ayahPlaybackSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPageData() async {
    final List<Map<String, int>> verses = [];
    final Set<String> uniqueVerses = {};

    // 🎯 Load ONLY the current page's verses INSTANTLY and OFFLINE
    final pageVersesData = await QuranTextService().getVersesByPage(widget.pageNumber);
    for (var verse in pageVersesData) {
      final vKey = verse['verse_key'] as String;
      final parts = vKey.split(':');
      final sNum = int.parse(parts[0]);
      final ayahNum = int.parse(parts[1]);
      
      final key = '$sNum:$ayahNum';
      if (!uniqueVerses.contains(key)) {
        uniqueVerses.add(key);
        verses.add({'surah': sNum, 'ayah': ayahNum});
      }
    }

    if (mounted) setState(() => _pageVerses = verses);
  }

  Future<void> _initPlayer({bool playAfterLoad = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final reciterId = widget.autoPlayReciter ?? (prefs.getString('selected_reciter_id') ?? 'al_afasy');
    
    await _loadPageData();

    if (mounted) {
      _selectedReciter = Reciter.defaultReciters.firstWhere((r) => r.id == reciterId);
      
      if (_pageVerses.isNotEmpty) {
        int startIdx = 0;
        if (widget.initialAyah != null) {
          // 🎯 Search for the PRECISE Ayah+Surah combination for absolute accuracy
          final idx = _pageVerses.indexWhere((v) => 
            v['ayah'] == widget.initialAyah && 
            (widget.initialSurah == null || v['surah'] == widget.initialSurah)
          );
          
          if (idx != -1) {
            startIdx = idx;
          } else {
            // Fallback: search by ayah only if surah doesn't match (should rarely happen on same page)
            final fallbackIdx = _pageVerses.indexWhere((v) => v['ayah'] == widget.initialAyah);
            startIdx = fallbackIdx != -1 ? fallbackIdx : 0;
          }
        } else if (widget.autoPlayContinues) {
          // 🚀 Seamless page transition from the AudioService's current state
          final currentState = _audioService.lastEmittedState;
          if (currentState != null && currentState.page == widget.pageNumber) {
            final idx = _pageVerses.indexWhere((v) => 
              v['surah'] == currentState.surah && v['ayah'] == currentState.ayah
            );
            startIdx = idx != -1 ? idx : 0;
          } else {
            startIdx = 0;
          }
        }

        debugPrint('🔄 Dynamic Sequence Init: Page ${widget.pageNumber} (Play: $playAfterLoad)');
        await _audioService.startAyahSequence(
          verses: _pageVerses,
          startIndex: startIdx,
          reciter: _selectedReciter!,
          playImmediately: playAfterLoad, // 🎯 Use the new flag
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if current playing Ayah is on this page to enable navigation buttons
    final int currentIdxInPage = _pageVerses.indexWhere((v) => v['surah'] == _currentSurah && v['ayah'] == _currentAyah);
    final bool hasNext = currentIdxInPage != -1 && currentIdxInPage < _pageVerses.length - 1;
    final bool hasPrev = currentIdxInPage != -1 && currentIdxInPage > 0;

    return Container(
      height: 64, // 🚀 Compact Height
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: _deepGreen.withValues(alpha: 0.95), // 🎨 Theme-aware
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _richGold.withValues(alpha: 0.3), width: 1.5), // 🎨 Theme-aware
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 🏆 Progress Line (Top)
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: StreamBuilder<Duration>(
              stream: _audioService.positionStream,
              builder: (context, snapshot) {
                final pos = snapshot.data ?? Duration.zero;
                final dur = _audioService.duration ?? Duration.zero;
                final progress = dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0.0;
                
                return Container(
                  height: 2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _richGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _richGold,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(color: _richGold.withValues(alpha: 0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 👳‍♂️ Reciter Selection (Left - Fixed Width)
                SizedBox(
                  width: 50,
                  child: _buildReciterSection(),
                ),
                
                // 🎮 Controls (Center - Expanded)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(child: _buildPlaybackControls(hasPrev, hasNext)),
                  ),
                ),
                
                // 📖 Ayah Info (Right - Constrained Width)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: _buildAyahInfoSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReciterSection() {
    return GestureDetector(
      onTap: _showReciterPicker,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _richGold.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 20, // 🚀 Smaller Avatar
              backgroundColor: _richGold.withValues(alpha: 0.1),
              backgroundImage: _selectedReciter != null ? NetworkImage(_selectedReciter!.imageUrl) : null,
              child: _selectedReciter == null ? Icon(Icons.person, color: _richGold, size: 20) : null,
            ),
            Container(
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(color: _richGold, shape: BoxShape.circle),
              child: const Icon(Icons.swap_horiz_rounded, size: 8, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(bool hasPrev, bool hasNext) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔁 Repetition Settings Button
        _buildCircularBtn(
          icon: Icons.repeat_one_rounded,
          enabled: true,
          onTap: _showRepetitionSettings,
          size: 20, // Smaller size
          color: (_ayahRepeatCount > 1 || _rangeRepeatCount > 1) ? _richGold : Colors.white54,
        ),
        const SizedBox(width: 4), // Reduced spacing

        _buildCircularBtn(
          icon: Icons.skip_previous_rounded,
          enabled: hasPrev,
          onTap: () => _audioService.previousAyah(),
          size: 22, // 🚀 Compact Icons
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              _audioService.pause();
            } else {
              _audioService.resume();
            }
            HapticFeedback.lightImpact();
          },
          child: StreamBuilder<PlayerState>(
            stream: _audioService.playerStateStream,
            builder: (context, snapshot) {
              final state = snapshot.data?.processingState;
              final isBuffering = state == ProcessingState.buffering || state == ProcessingState.loading;
              
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _richGold,
                  boxShadow: [
                    BoxShadow(color: _richGold.withValues(alpha: 0.2), blurRadius: 8),
                  ],
                ),
                child: isBuffering 
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: widget.theme == ThemeService.mushafPremium ? const Color(0xFF33270F) : Colors.black,
                      size: 28,
                    ),
              );
            }
          ),
        ),
        const SizedBox(width: 12),
        _buildCircularBtn(
          icon: Icons.skip_next_rounded,
          enabled: hasNext,
          onTap: () => _audioService.nextAyah(),
          size: 22,
        ),
      ],
    );
  }

  Widget _buildAyahInfoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _currentAyah > 0 ? 'سورة ${QuranPageHelper.surahNames[_currentSurah - 1]}' : 'جاهز للتلاوة',
          style: GoogleFonts.amiri(
            color: _richGold,
            fontSize: 13, // 🚀 Compact Text
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // RTL feel
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_ayahRepeatCount > 1) 
                _buildIterationBadge('$_currentAyahIteration/$_ayahRepeatCount', _richGold),
              if (_rangeRepeatCount > 1)
                _buildIterationBadge('الجولة $_currentRangeIteration', Colors.blue[300]!),
              
              if (_selectedReciter != null && _currentSurah > 0)
                _buildDownloadIndicator(),

              Text(
                _currentAyah > 0 ? 'آية $_currentAyah' : 'اختر آية',
                style: GoogleFonts.amiri(
                  color: AppColors.textMuted,
                  fontSize: 11, // Slightly smaller
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIterationBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDownloadIndicator() {
    return FutureBuilder<bool>(
      future: _audioService.isSurahDownloaded(_selectedReciter!.id, _currentSurah),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.offline_pin_rounded, color: Colors.green, size: 10),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCircularBtn({
    required IconData icon, 
    required bool enabled, 
    required VoidCallback onTap, 
    double size = 30,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, color: color ?? (enabled ? _richGold : Colors.white24), size: size),
      onPressed: enabled ? onTap : null,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  void _showRepetitionSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _deepGreen.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: _richGold.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Text('إعدادات التكرار (الحفظ) 📖', style: GoogleFonts.amiri(color: _richGold, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Ayah Repeat
                _buildRepeatInRow(
                  label: 'تكرار الآية الواحدة',
                  value: _ayahRepeatCount,
                  onChanged: (val) {
                    _audioService.setAyahRepeatCount(val);
                    setModalState(() => _ayahRepeatCount = val);
                    setState(() {});
                  },
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.white10),
                ),
                
                // Range Repeat
                _buildRepeatInRow(
                  label: 'تكرار الصفحة / النطاق الكامل',
                  value: _rangeRepeatCount,
                  onChanged: (val) {
                    _audioService.setRangeRepeatCount(val);
                    setModalState(() => _rangeRepeatCount = val);
                    setState(() {});
                  },
                ),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _richGold,
                      foregroundColor: widget.theme == ThemeService.mushafPremium ? const Color(0xFF33270F) : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('تم', style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildRepeatInRow({required String label, required int value, required Function(int) onChanged}) {
    final options = [1, 2, 3, 5, 10, 0]; // 0 = infinite
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: GoogleFonts.amiri(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((opt) {
                final isSelected = value == opt;
                return GestureDetector(
                  onTap: () => onChanged(opt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _richGold : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? _richGold : Colors.white24, width: 1.5),
                    ),
                    child: Text(
                      opt == 0 ? '∞' : '$opt',
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showReciterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: _deepGreen.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: _richGold.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('اختر القارئ', style: GoogleFonts.amiri(color: _richGold, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: Reciter.defaultReciters.length,
                itemBuilder: (context, index) {
                  final r = Reciter.defaultReciters[index];
                  final isSelected = _selectedReciter?.id == r.id;
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(r.imageUrl)),
                    title: Text(r.name, style: GoogleFonts.amiri(color: isSelected ? _richGold : Colors.white, fontSize: 18)),
                    trailing: isSelected ? Icon(Icons.check_circle, color: _richGold) : null,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selected_reciter_id', r.id);
                      if (mounted) {
                        setState(() => _selectedReciter = r);
                        // Restart sequence with new reciter if already in one
                        if (_pageVerses.isNotEmpty) {
                          final idx = _pageVerses.indexWhere((v) => v['surah'] == _currentSurah && v['ayah'] == _currentAyah);
                          await _audioService.startAyahSequence(
                            verses: _pageVerses,
                            startIndex: idx != -1 ? idx : 0,
                            reciter: r,
                          );
                        }
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
