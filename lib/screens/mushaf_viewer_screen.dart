import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../widgets/mushaf_audio_player.dart';
import '../widgets/ai_tajweed_sheet.dart';
import '../services/recitation_recognition_service.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/khatma_service.dart';
import '../services/settings_service.dart';
import '../services/kids_mode_service.dart';
import '../services/theme_service.dart';
import '../services/quran_text_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/mushaf_page_renderer.dart';
import '../widgets/mushaf_settings_dialog.dart';
import '../widgets/ayah_interaction_bubble.dart';
import '../widgets/mushaf_navigation_picker.dart';
import 'tafseer_screen.dart';

// ============================================================
//  PREMIUM COLORS & THEME HELPERS
// ============================================================
String _currentTheme = ThemeService.mushafClassic;

Color get _deepGreen {
  switch (_currentTheme) {
    case ThemeService.mushafPremium: return const Color(0xFF33270F);
    case ThemeService.mushafDark: return const Color(0xFF05110E);
    default: return const Color(0xFF031E17);
  }
}

Color get _richGold {
  switch (_currentTheme) {
    case ThemeService.mushafDark: return const Color(0xFFD4A947).withValues(alpha: 0.6);
    default: return const Color(0xFFD4A947);
  }
}

Color get _lightGold {
  return _richGold.withValues(alpha: 0.8);
}

Color get _darkGold {
  return _richGold.withValues(alpha: 1.2);
}

Color get _parchment {
  switch (_currentTheme) {
    case ThemeService.mushafPremium: return const Color(0xFFFFF8E1);
    case ThemeService.mushafDark: return const Color(0xFFE0E0E0);
    default: return const Color(0xFFFDF5E6);
  }
}

Color get _parchmentDark {
  switch (_currentTheme) {
    case ThemeService.mushafPremium: return const Color(0xFFFFECB3);
    case ThemeService.mushafDark: return const Color(0xFFBDBDBD);
    default: return const Color(0xFFF5E6C8);
  }
}

const Color _pageShadow = Color(0x33000000);

/// Premium Mushaf Viewer — عارض المصحف الاحترافي
/// A realistic, premium 3D Quran viewer experience
class MushafViewerScreen extends StatefulWidget {
  final int initialPage;

  const MushafViewerScreen({super.key, this.initialPage = 1});

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showAudioPlayer = false;
  bool _showBars = true;
  bool _isLoading = true;
  String _currentSurahName = '';
  int _currentJuz = 1;
  
  final QuranTextService _quranService = QuranTextService();

  bool _isMemorizationMode = false;
  bool _isPeeking = false;

  // Highlighting state
  int? _activeAyah;
  int? _tappedAyah; // New: to track specifically tapped ayah
  String? _highlightedWordLocation; // 🎯 New for Phase 64
  bool _isSanctuaryMode = false;
  
  // Optimization
  int _lastLoadId = 0; // Race condition protection
  Timer? _statsTimer;

  // Real Mushaf Settings
  double _quranFontSize = 24.0;
  double _translationFontSize = 16.0;
  String _selectedFont = ThemeService.fontAmiri;
  String _selectedEdition = ThemeService.editionMadina1405;

  // Interaction Bubble State
  bool _showBubble = false;
  String _bubbleTranslation = '';
  String _bubbleTafseer = '';
  int? _bubbleSurah;
  int? _bubbleAyah;

  bool _isVerticalMode = false; // New: Toggle for scrolling direction

  // Animation controllers for premium effects
  late AnimationController _barAnimController;
  late Animation<double> _barSlideAnimation;

  // Page turning shadow animation
  late AnimationController _pageTurnController;

  // Sanctuary Mode (Breathing Glow)
  late AnimationController _sanctuaryController;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _loadPageData(widget.initialPage);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _barAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _barSlideAnimation = CurvedAnimation(
      parent: _barAnimController,
      curve: Curves.easeOutCubic,
    );
    _barAnimController.forward();

    _pageTurnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sanctuaryController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _loadTheme();
    _initWakelock();
  }

  Future<void> _initWakelock() async {
    final keepScreenOn = await SettingsService.getKeepScreenOn();
    if (keepScreenOn) {
      WakelockPlus.enable();
    }
  }

  Future<void> _handleAyahTap(int surah, int ayah) async {
    debugPrint('🎯 Tapped Ayah via Dynamic Renderer: $ayah');
    
    // Set loading/active state
    setState(() {
      _tappedAyah = ayah;
      _activeAyah = ayah;
      _bubbleSurah = surah;
      _bubbleAyah = ayah;
    });

    HapticFeedback.mediumImpact();

    try {
      // 1. Fetch Translation (ID 131 is usually a good English/Arabic default, but let's use 16 for Tafseer as well)
      final translation = await _quranService.getTranslation(surah, ayah, 131);
      
      // 2. Fetch Tafseer
      final tafseerData = await _quranService.getTafseer(surah, ayah);
      final tafseer = tafseerData['text'] ?? "لا يوجد تفسير متاح.";

      if (mounted) {
        setState(() {
          _bubbleTranslation = translation;
          _bubbleTafseer = tafseer;
          _showBubble = true;
          _showAudioPlayer = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching bubble data: $e');
    }
  }

  void _enterSanctuaryMode() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSanctuaryMode = true;
      _showBars = false;
      _showAudioPlayer = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitSanctuaryMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSanctuaryMode = false;
      _showBars = true;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _barAnimController.forward();
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _pageController.dispose();
    _barAnimController.dispose();
    _pageTurnController.dispose();
    _sanctuaryController.dispose();
    
    // Disable wakelock on exit
    WakelockPlus.disable();
    
    // Safety: Reset UI mode
    Future.delayed(Duration.zero, () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
    
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getMushafTheme();
    final qSize = await ThemeService.getQuranFontSize();
    final tSize = await ThemeService.getTranslationFontSize();
    final font = await ThemeService.getThemeFont();
    final edition = await ThemeService.getMushafEdition();

    final method = await SettingsService.getReadingMethod();
    
    if (mounted) {
      setState(() {
        _currentTheme = theme;
        _quranFontSize = qSize;
        _translationFontSize = tSize;
        _selectedFont = font;
        _selectedEdition = edition;
        _isVerticalMode = method == ReadingMethod.scroll;
      });
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MushafSettingsDialog(
        onQuranFontSizeChanged: (val) => setState(() => _quranFontSize = val),
        onTranslationFontSizeChanged: (val) => setState(() => _translationFontSize = val),
        onFontChanged: (val) => setState(() => _selectedFont = val),
        onThemeChanged: (val) => setState(() {
          _currentTheme = val;
          // Trigger global theme update if needed
        }),
        onEditionChanged: (val) => setState(() => _selectedEdition = val),
      ),
    );
  }

  Future<void> _loadPageData(int pageNumber, {bool isBackground = false}) async {
    final currentLoadId = ++_lastLoadId;
    
    if (!isBackground) setState(() => _isLoading = true);
    
    // Check if this request is still relevant
    if (currentLoadId != _lastLoadId) return;

    // Surah/Juz info is handled by QuranPageHelper
    _currentSurahName = QuranPageHelper.getSurahNameForPage(pageNumber);
    _currentJuz = QuranPageHelper.getJuzForPage(pageNumber);

    // Stop loading indicator
    if (!isBackground) setState(() => _isLoading = false);
    if (isBackground && mounted) {
      setState(() {
        // Highlighting is now handled internally by MushafPageRenderer
      });
    }
  }

  void _recordPageVisit(int page) {
    _statsTimer?.cancel();
    _statsTimer = Timer(const Duration(seconds: 1), () async {
      BookmarkService.saveLastRead(
        surahNumber: 0,
        surahName: 'المصحف',
        pageNumber: page,
      );
      StreakService.recordReading();
      // تسجيل التقدم في الختمات والخطط
      await KhatmaService.recordPageProgress(_currentPage);
    });
  }

  void _showNavigationPicker() async {
    HapticFeedback.heavyImpact();
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MushafNavigationPicker(
        initialJuz: _currentJuz,
        initialSurah: QuranPageHelper.getSurahForPage(_currentPage),
        initialAyah: _activeAyah ?? 1,
        theme: _currentTheme,
      ),
    );

    if (result != null && mounted) {
      final surah = result['surah']!;
      final ayah = result['ayah']!;
      _navigateToAyah(surah, ayah);
    }
  }

  Future<void> _navigateToAyah(int surah, int ayah) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Find the page number for this (surah, ayah)
    int targetPage = QuranPageHelper.getPageForSurah(surah);
    
    try {
      bool found = false;
      for (int p = targetPage; p <= 604; p++) {
        final verses = await _quranService.getVersesByPage(p);
        final hasAyah = verses.any((v) {
          final parts = v['verse_key'].split(':'); // e.g. "2:185"
          return int.parse(parts[0]) == surah && int.parse(parts[1]) == ayah;
        });

        if (hasAyah) {
          targetPage = p;
          found = true;
          break;
        }
        
        final pageSurah = QuranPageHelper.getSurahForPage(p);
        if (pageSurah > surah) break; 
      }
      
      if (mounted) {
        // 🚀 إصلاح: التأكد من ربط الـ Controller قبل القفز (Safety Fix)
        // Ensure controller is attached before jumping
        if (_pageController.hasClients) {
          _pageController.jumpToPage(targetPage - 1);
        } else {
          // Fallback: Use post-frame if not yet attached
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.jumpToPage(targetPage - 1);
            }
          });
        }

        setState(() {
          _currentPage = targetPage;
          _activeAyah = ayah;
          _tappedAyah = ayah;
          _isLoading = false;
        });
        _loadPageData(targetPage, isBackground: true);
        _recordPageVisit(targetPage);
        
        if (!found) {
           debugPrint('⚠️ Ayah $surah:$ayah not found in precision search, landed on Surah start page $targetPage');
        }
      }
    } catch (e) {
      debugPrint('❌ Error navigating to ayah: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleFullscreen() {
    setState(() => _showBars = !_showBars);
    if (_showBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _barAnimController.forward();
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _barAnimController.reverse();
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final kidsMode = Provider.of<KidsModeService>(context);
    final isKids = kidsMode.isKidsModeActive;
    final primaryColor = isKids ? kidsMode.primaryColor : _richGold;
    final bgColor = isKids ? kidsMode.backgroundColor : _deepGreen;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? _buildLoadingState()
          : GestureDetector(
              onTap: _toggleFullscreen,
              child: Stack(
                children: [
                  // === الخلفية المزخرفة ===
                  if (!isKids && !_isSanctuaryMode) 
                    const Positioned.fill(
                      key: ValueKey('mushaf_bg'),
                      child: _PremiumBackground(),
                    ),

                  // === إطار المصحف الخارجي ===
                  Positioned.fill(
                    key: const ValueKey('mushaf_book_frame'),
                    child: _buildBookFrame(),
                  ),

                  // === محراب التلاوة Overlay ===
                    Positioned.fill(
                      key: const ValueKey('mushaf_sanctuary_overlay'),
                      child: _SanctuaryOverlay(
                        controller: _sanctuaryController,
                        onExit: _exitSanctuaryMode,
                      ),
                    ),

                  // === Ayah Interaction Bubble (Premium Floating Layer) ===
                  if (_showBubble && _bubbleSurah != null && _bubbleAyah != null)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => _showBubble = false),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.1), // Dim background
                          child: Center(
                            child: AyahInteractionBubble(
                              surah: _bubbleSurah!,
                              ayah: _bubbleAyah!,
                              translation: _bubbleTranslation,
                              tafseer: _bubbleTafseer,
                              fontSize: _translationFontSize,
                              onPlay: () {
                                // Play logic is already triggered in _handleAyahTap
                              },
                              onClose: () => setState(() => _showBubble = false),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // === الشريط العلوي ===
                  _buildPremiumTopBar(isKids: isKids, kidsMode: kidsMode),

                  // === الشريط السفلي ===
                  _buildPremiumBottomBar(isKids: isKids, kidsMode: kidsMode),

                  // === مشغل الصوت ===
                  Positioned(
                    key: const ValueKey('mushaf_audio_player_container'),
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showAudioPlayer
                          ? MushafAudioPlayer(
                              key: ValueKey('mushaf_audio_player_$_currentPage$_tappedAyah'),
                              pageNumber: _currentPage,
                              initialAyah: _tappedAyah,
                              onAyahChanged: (surah, ayah) {
                                debugPrint('🔊 Ayah Changed: $surah:$ayah');
                                if (mounted) {
                                  setState(() {
                                    _activeAyah = ayah;
                                    _highlightedWordLocation = null; // Reset word highlight
                                  });
                                }
                              },
                              onWordChanged: (loc) {
                                if (mounted) setState(() => _highlightedWordLocation = loc);
                              },
                              onMemorizationModeChanged: (isBlurring) {
                                if (mounted) {
                                  setState(() {
                                    _isMemorizationMode = isBlurring;
                                  });
                                }
                              },
                              onClose: () {
                                setState(() {
                                  _showAudioPlayer = false;
                                  _activeAyah = null;
                                  _highlightedWordLocation = null; // Reset
                                  _isMemorizationMode = false;
                                  _tappedAyah = null; // Reset tapped ayah
                                });
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  // === زر مختبر التجويد AI ===
                  if (_showBars && !_showAudioPlayer)
                    Positioned(
                      bottom: 100,
                      right: 24,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: FloatingActionButton(
                          onPressed: () => _openAITajweedLab(),
                          backgroundColor: isKids ? primaryColor : AppColors.gold,
                          elevation: 8,
                          child: Icon(isKids ? Icons.face_rounded : Icons.psychology_rounded, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  // === زر التعرّف على التلاوة (🎙️) ===
                  if (_showBars && !_showAudioPlayer)
                    Positioned(
                    bottom: 100,
                    left: 24,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: FloatingActionButton(
                        onPressed: () => _recognizeCurrentRecitation(),
                        backgroundColor: Colors.blueAccent,
                        elevation: 8,
                        child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _recognizeCurrentRecitation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري الاستماع للتعرف على الآية...'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.blueAccent,
      ),
    );

    final result = await RecitationRecognitionService().recognizeAyah();
    
    if (result != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تم التعرّف على الآية',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 22, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                'سورة الفاتحة - آية ${result.ayah}',
                style: GoogleFonts.amiri(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('حسناً', style: GoogleFonts.amiri(color: AppColors.gold)),
            ),
          ],
        ),
      );
    }
  }

  void _openAITajweedLab() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AITajweedSheet(
        surah: QuranPageHelper.getSurahForPage(_currentPage),
        ayah: _activeAyah ?? 1,
      ),
    );
  }

  // ============================================================
  //  LOADING STATE
  // ============================================================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _richGold.withValues(alpha: 0.3), width: 2),
            ),
            child: CircularProgressIndicator(
              color: _richGold,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جارٍ فتح المصحف...',
            style: GoogleFonts.amiri(
              color: _richGold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  //  BOOK FRAME — إطار المصحف
  // ============================================================
  Widget _buildBookFrame() {
    return Column(
      children: [
        // Expanded Mushaf area filling the screen
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              // ظل خفيف جداً للحفاظ على التفاصيل
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _richGold.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _darkGold.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                      child: Stack(
                        children: [
                          // خلفية الصفحة (ورق عتيق)
                          Container(
                            key: const ValueKey('mushaf_parchment_bg'),
                            color: _parchment,
                          ),
                          
                          // Sanctuary Darken Layer
                          if (_isSanctuaryMode)
                            Positioned.fill(
                              key: const ValueKey('mushaf_sanctuary_darken'),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 1000),
                                color: Colors.black.withValues(alpha: 0.12),
                              ),
                            ),

                          Directionality(
                            key: const ValueKey('mushaf_page_view_wrapper'),
                            textDirection: TextDirection.rtl,
                            child: PageView.builder(
                              key: const PageStorageKey('mushaf_page_view'),
                              controller: _pageController,
                              scrollDirection: _isVerticalMode ? Axis.vertical : Axis.horizontal,
                              clipBehavior: Clip.none, // Essential for showing curl outside bounds
                              reverse: false, // Page 1 on right, Swipe R->L advances
                              itemCount: 604,
                              onPageChanged: (index) {
                                final page = index + 1;
                                
                                // Premium Haptic Feedback on Page Turn (especially for vertical mode)
                                if (_isVerticalMode) {
                                  HapticFeedback.selectionClick();
                                }
              
                                // اهتزاز خفيف جداً عند تقليب الصفحة — Subtle haptic feedback
                                HapticFeedback.lightImpact();

                                setState(() {
                                  _currentPage = page;
                                  _currentSurahName = QuranPageHelper.getSurahNameForPage(page);
                                  _currentJuz = QuranPageHelper.getJuzForPage(page);
                                });
                                _loadPageData(page, isBackground: true);
                                _recordPageVisit(page);
                              },
                              itemBuilder: (context, index) {
                                return AnimatedBuilder(
                                  animation: _pageController,
                                  builder: (context, child) {
                                    final pageNumber = index + 1;
                                    double angle = 0.0;
                                    double pageOffset = 0.0;

                                    if (_pageController.hasClients && _pageController.position.haveDimensions) {
                                      try {
                                        pageOffset = _pageController.page! - index;
                                      } catch (e) {
                                        // Safety for build synchronization
                                        pageOffset = 0.0;
                                      }
                                    }
                                    
                                    // THE HYPER-REALISTIC "CYLINDRICAL CURL"
                                    // Only show curl in horizontal mode
                                    if (!_isVerticalMode && pageOffset > 0 && pageOffset < 1) {
                                      // 1. Calculations for the curl geometry
                                      angle = (pageOffset * math.pi).clamp(0.0, math.pi);
                                      
                                      final double curlFactor = math.sin(pageOffset * math.pi);
                                      final double zProtrusion = curlFactor * 140; 
                                      
                                      final bool isBackFace = angle > (math.pi / 2);

                                      return Transform(
                                        alignment: Alignment.centerRight,
                                        transform: Matrix4.identity()
                                          ..setEntry(0, 3, pageOffset * MediaQuery.of(context).size.width)
                                          ..setEntry(3, 2, 0.0012)
                                          ..setEntry(2, 3, zProtrusion)
                                          ..rotateY(angle)
                                          ..setEntry(1, 0, pageOffset * 0.15 * (isBackFace ? 1 : -1))
                                          ..rotateX(-pageOffset * 0.06),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: Container(
                                                margin: EdgeInsets.only(right: 40 + (1.0 - pageOffset) * 100),
                                                decoration: BoxDecoration(
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: (curlFactor * 0.5).clamp(0.0, 0.5)),
                                                      blurRadius: 40,
                                                      offset: const Offset(20, 0),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            ClipPath(
                                              clipper: _CylindricalPageClipper(progress: pageOffset),
                                              child: Stack(
                                                children: [
                                                  RepaintBoundary(
                                                    child: isBackFace 
                                                      ? Transform(
                                                          alignment: Alignment.center,
                                                          transform: Matrix4.rotationY(math.pi),
                                                          child: Container(
                                                            color: _parchmentDark,
                                                            child: ColorFiltered(
                                                              colorFilter: ColorFilter.mode(
                                                                Colors.black.withValues(alpha: 0.8),
                                                                BlendMode.srcOver,
                                                              ),
                                                              child: _buildPremiumPage(pageNumber + 1),
                                                            ),
                                                          ),
                                                        )
                                                      : _buildPremiumPage(pageNumber),
                                                  ),

                                                  Positioned.fill(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: isBackFace ? Alignment.centerLeft : Alignment.centerRight,
                                                          end: isBackFace ? Alignment.centerRight : Alignment.centerLeft,
                                                          stops: const [0.0, 0.45, 0.55, 1.0],
                                                          colors: [
                                                            Colors.black.withValues(alpha: isBackFace ? 0.4 : 0.1),
                                                            Colors.transparent,
                                                            Colors.white.withValues(alpha: curlFactor * 0.35),
                                                            Colors.black.withValues(alpha: isBackFace ? 0.1 : 0.5),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } 

                                    return _buildPremiumPage(pageNumber);
                                  },
                                );
                              },
                            ),
                          ),

                          // ظل الكعب على الصفحة
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 25,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    _pageShadow,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // إطار زخرفي داخلي
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _richGold.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }


  // ============================================================
  //  PREMIUM PAGE — الصفحة المزخرفة
  // ============================================================
  Widget _buildPremiumPage(int pageNumber) {
    return Container(
      color: _parchment,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Page Content - Main Renderer handles its own interactivity and ornaments
          _buildPageImage(pageNumber),

          // Blur layer for memorization mode (Overlay on top)
          if (_isMemorizationMode && !_isPeeking)
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => setState(() => _isPeeking = true),
                onPointerUp: (_) => setState(() => _isPeeking = false),
                onPointerCancel: (_) => setState(() => _isPeeking = false),
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageImage(int pageNumber) {
    // We prioritize the Smart Vector Mushaf to ensure precision and interactive features
    return _buildVectorPage(pageNumber);
  }

  Widget _buildVectorPage(int pageNumber) {
    return MushafPageRenderer(
      pageNumber: pageNumber,
      highlightedSurah: QuranPageHelper.getSurahForPage(pageNumber),
      highlightedAyah: _activeAyah,
      highlightedWordLocation: _highlightedWordLocation, // 🎯 New for Phase 64
      isMemorizationMode: _isMemorizationMode,
      theme: _currentTheme,
      onAyahTapped: (surah, ayah) => _handleAyahTap(surah, ayah),
      fontSize: _quranFontSize,
      fontFamily: _selectedFont,
      edition: _selectedEdition,
      pageController: _pageController,
    );
  }

  // ============================================================
  //  PREMIUM TOP BAR
  // ============================================================
  Widget _buildPremiumTopBar({bool isKids = false, KidsModeService? kidsMode}) {
    final primaryColor = isKids ? kidsMode?.primaryColor ?? _richGold : _richGold;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: _isSanctuaryMode ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: _isSanctuaryMode,
          child: AnimatedBuilder(
            animation: _barSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -60 * (1 - _barSlideAnimation.value)),
                child: child,
              );
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 5, 16, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _deepGreen,
                    _deepGreen.withValues(alpha: 0.97),
                    _deepGreen.withValues(alpha: 0.85),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: _richGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  _PremiumIconButton(
                    icon: Icons.self_improvement_rounded,
                    onPressed: _enterSanctuaryMode,
                  ),
                  const SizedBox(width: 8),

                  // زر وضع القراءة (Vertical vs Horizontal)
                  _PremiumIconButton(
                    icon: _isVerticalMode ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
                    onPressed: () async {
                      final newMode = !_isVerticalMode;
                      setState(() {
                         _isVerticalMode = newMode;
                      });
                      await SettingsService.setReadingMethod(
                        newMode ? ReadingMethod.scroll : ReadingMethod.pages
                      );
                      HapticFeedback.mediumImpact();
                    },
                  ),
                  const SizedBox(width: 8),

                  // زر الإعدادات (Real Mushaf Settings)
                  _PremiumIconButton(
                    icon: Icons.settings_rounded,
                    onPressed: _showSettings,
                  ),
                  const SizedBox(width: 8),
                  
                  _PremiumIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  const Spacer(),

                  // معلومات السورة والجزء
                  GestureDetector(
                    onTap: _showNavigationPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _richGold.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _richGold.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentSurahName,
                                style: GoogleFonts.amiri(
                                  color: primaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor.withValues(alpha: 0.6), size: 20),
                            ],
                          ),
                          Text(
                            'الجزء $_currentJuz',
                            style: GoogleFonts.amiri(
                              color: _lightGold.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // زر الخيارات
                  _PremiumIconButton(
                    icon: Icons.more_vert_rounded,
                    onPressed: () => _showPageOptions(context, _currentPage),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  PREMIUM BOTTOM BAR
  // ============================================================
  Widget _buildPremiumBottomBar({bool isKids = false, KidsModeService? kidsMode}) {
    final primaryColor = isKids ? kidsMode?.primaryColor ?? _richGold : _richGold;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: _isSanctuaryMode ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: _isSanctuaryMode,
          child: AnimatedBuilder(
            animation: _barSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 60 * (1 - _barSlideAnimation.value)),
                child: child,
              );
            },
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _deepGreen,
                    _deepGreen.withValues(alpha: 0.97),
                    _deepGreen.withValues(alpha: 0.85),
                  ],
                ),
                border: Border(
                  top: BorderSide(
                    color: _richGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // رقم الصفحة مزخرف
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _richGold.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'صفحة $_currentPage',
                      style: GoogleFonts.amiri(
                        color: primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // نقاط التقدم
                  Text(
                    '${(_currentPage / 604 * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      color: _lightGold.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // زر المشاركة
                  _PremiumIconButton(
                    icon: Icons.share_rounded,
                    size: 22,
                    onPressed: () => _shareCurrentPage(),
                  ),

                  const SizedBox(width: 8),

                  // زر الحفظ
                  _PremiumIconButton(
                    icon: Icons.bookmark_border_rounded,
                    size: 22,
                    onPressed: () async {
                      await BookmarkService.addPageBookmark(pageNumber: _currentPage);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _richGold.withValues(alpha: 0.2),
                                    _richGold.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: _richGold.withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'تم حفظ الصفحة $_currentPage ✓',
                                style: GoogleFonts.amiri(color: Colors.white),
                              ),
                            ),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _richGold.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ============================================================
  //  SHARE CURRENT PAGE
  // ============================================================
  void _shareCurrentPage() {
    final text = '📖 $_currentSurahName\n'
        '📄 صفحة $_currentPage — الجزء $_currentJuz\n'
        '\n'
        '~ تلا قرآن 🕌';
    Share.share(text);
  }

  // ============================================================
  //  PAGE OPTIONS MODAL
  // ============================================================
  void _showPageOptions(BuildContext context, int pageNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          decoration: BoxDecoration(
            color: _deepGreen,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: _richGold.withValues(alpha: 0.5), width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: _richGold.withValues(alpha: 0.1),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // المقبض
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _richGold.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // العنوان
                Text(
                  '❁ خيارات الصفحة $pageNumber ❁',
                  style: GoogleFonts.amiri(
                    color: _richGold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // الأزرار
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPremiumOption(
                      icon: Icons.play_arrow_rounded,
                      label: 'تشغيل',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _showAudioPlayer = true);
                      },
                    ),
                    _buildPremiumOption(
                      icon: Icons.menu_book_rounded,
                      label: 'التفسير',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TafseerScreen(
                              surahNumber:
                                  QuranPageHelper.getSurahForPage(pageNumber),
                              ayahNumber: 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildPremiumOption(
                      icon: Icons.bookmark_add_rounded,
                      label: 'حفظ',
                      onTap: () async {
                        Navigator.pop(context);
                        await BookmarkService.addPageBookmark(
                            pageNumber: pageNumber);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حفظ الصفحة $pageNumber ✓',
                              style: GoogleFonts.amiri(color: Colors.white),
                            ),
                            backgroundColor: _deepGreen,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _richGold.withValues(alpha: 0.4),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _richGold.withValues(alpha: 0.1),
                  _richGold.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(icon, color: _richGold, size: 26),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.amiri(
            color: _lightGold.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
//  CUSTOM PAINTERS & WIDGETS
// ============================================================

/// خلفية مزخرفة للتطبيق
class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PremiumBackgroundPainter(),
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // تدرج أساسي
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.cardBackground,
          AppColors.background,
          AppColors.background,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // حلقات زخرفية خفيفة
    final ornamentPaint = Paint()
      ..color = const Color(0xFFD4A947).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 1; i <= 8; i++) {
      canvas.drawCircle(Offset(cx, cy), i * 80.0, ornamentPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// زر أيقونة بتأثير ذهبي
class _PremiumIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  const _PremiumIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: const Color(0xFFD4A947), size: size),
      onPressed: onPressed,
      splashColor: const Color(0xFFD4A947).withValues(alpha: 0.15),
      highlightColor: const Color(0xFFD4A947).withValues(alpha: 0.05),
    );
  }
}

// ============================================================
//  SANCTUARY MODE WIDGETS
// ============================================================

class _SanctuaryOverlay extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onExit;

  const _SanctuaryOverlay({required this.controller, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onExit,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.15), // Subtle darken
        child: Stack(
          children: [
            // Breathing Glow
            _SanctuaryBreathingGlow(controller: controller),
            
            // Focus Hint (Top)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.2 + (controller.value * 0.3),
                      child: child,
                    );
                  },
                  child: Text(
                    'محراب التلاوة',
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Flow Indicator (Bottom)
            Positioned(
              bottom: 60,
              left: 60,
              right: 60,
              child: _SanctuaryFlowIndicator(controller: controller),
            ),

            // Exit instructions
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'اضغط مطولاً للخروج من المحراب',
                  style: GoogleFonts.amiri(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SanctuaryBreathingGlow extends StatelessWidget {
  final AnimationController controller;
  const _SanctuaryBreathingGlow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.08 * controller.value),
                Colors.transparent,
              ],
              radius: 0.7 + (controller.value * 0.5),
            ),
          ),
        );
      },
    );
  }
}

class _SanctuaryFlowIndicator extends StatelessWidget {
  final AnimationController controller;
  const _SanctuaryFlowIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 1.2,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.gold.withValues(alpha: 0.1 + (0.3 * controller.value)),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Clipper for the Cylindrical Page Curl effect
class _CylindricalPageClipper extends CustomClipper<Path> {
  final double progress;
  _CylindricalPageClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;
    
    // Aggressive curl for "WOW" factor
    final double curlFactor = math.sin(progress * math.pi);
    final double curveWidth = curlFactor * 100.0;
    final double curveHeight = curlFactor * 50.0;

    path.moveTo(0, 0);
    // Top Edge with non-linear curve
    path.quadraticBezierTo(w * 0.4, -curveHeight * 1.5, w, 0);
    // Curved Right Edge (the "Pull" edge)
    path.cubicTo(w + curveWidth, h * 0.2, w + curveWidth, h * 0.8, w, h);
    // Bottom Edge with non-linear curve
    path.quadraticBezierTo(w * 0.4, h + curveHeight * 1.5, 0, h);
    path.lineTo(0, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(_CylindricalPageClipper oldClipper) => oldClipper.progress != progress;
}

