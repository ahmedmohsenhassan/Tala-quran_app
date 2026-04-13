import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';
import '../services/firebase_khatma_service.dart';

import '../widgets/mushaf_audio_player.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/khatma_service.dart';
import '../services/settings_service.dart';
import '../services/kids_mode_service.dart';
import '../services/theme_service.dart';
import '../services/reading_stats_service.dart';
import '../services/quran_text_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import 'tafseer_screen.dart';
import '../services/smart_notification_service.dart'; // 🔔 Smart Nudges
import 'main_dashboard_screen.dart';

import '../widgets/mushaf_page_renderer.dart';
import '../widgets/ayah_interaction_bubble.dart';
import '../widgets/mushaf_navigation_picker.dart';



// ============================================================
//  PREMIUM COLORS & THEMES
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


/// Premium Mushaf Viewer — عارض المصحف الاحترافي
/// A realistic, premium 3D Quran viewer experience
class MushafViewerScreen extends StatefulWidget {
  final int initialPage;
  final int? initialAyah; // 🔗 New for Phase 112
  final int? initialSurah; // 🔗 New for Phase 112
  final String? sharedKhatmaId;
  final bool autoPlay;
  final String? autoPlayReciter;

  const MushafViewerScreen({
    super.key, 
    this.initialPage = 1,
    this.initialAyah,
    this.initialSurah,
    this.sharedKhatmaId,
    this.autoPlay = false,
    this.autoPlayReciter,
  });

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showBars = true;
  bool _isLoading = true;
  String _currentSurahName = '';
  int _currentJuz = 1;
  
  final QuranTextService _quranService = QuranTextService();

  bool _isMemorizationMode = false;
  bool _isPeeking = false;

  // Highlighting state
  int? _activeAyah;
  int? _activeSurah; // 🎯 NEW: Highlighting by Surah+Ayah
  int? _tappedAyah; // New: to track specifically tapped ayah
  int? _tappedSurah;
  String? _highlightedWordLocation; // 🎯 New for Phase 64
  bool _isSanctuaryMode = false;
  
  // Optimization
  int _lastLoadId = 0; // Race condition protection
  Timer? _statsTimer;
  Timer? _uiIdleTimer; // ⏱️ New: UI Auto-hide Timer

  // Real Mushaf Settings
  double _quranFontSize = 24.0;
  double _translationFontSize = 16.0;
  String _selectedFont = ThemeService.fontAmiri;
  String _selectedEdition = ThemeService.editionMadina1405;

  // Interaction State
  int? _selectedAyah; // For contextual top bar selection
  int? _selectedSurah;

  bool _isVerticalMode = false; // New: Toggle for scrolling direction
  bool _showPageSlider = false; // 📜 New for Phase 115
  bool _isAudioContinuing = false; // 🔄 New: Tracks auto-turn from audio player

  // Animation controllers for premium effects
  late AnimationController _barAnimController;
  late Animation<double> _barSlideAnimation;

  // Page turning shadow animation
  late AnimationController _pageTurnController;

  // Sanctuary Mode (Breathing Glow)
  late AnimationController _sanctuaryController;

  // Reading Session Timer ⏱️
  final Stopwatch _sessionStopwatch = Stopwatch();
  Timer? _sessionTickTimer;
  String _sessionTimeDisplay = '00:00';

  // Bookmarked Pages 🔖
  Set<int> _bookmarkedPages = {};

  // Mini-Map Slider 📜
  int? _previewPage;
  bool _isScrubbing = false;
  bool _isPageZoomed = false;
  bool _showTajweed = false; // 🖌️ New for Phase 103
  
  // 📡 Collaborative Khatma State (Phase 105)
  late final FirebaseKhatmaService _firebaseKhatma;
  Stream<SharedKhatma>? _khatmaStream;

  StreamSubscription? _globalAudioSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _currentPage = widget.initialPage;
    
    // 🎯 Use Surah to determine page if provided (e.g. from Deep-link)
    if (widget.initialSurah != null) {
      _currentPage = QuranPageHelper.getPageForSurah(widget.initialSurah!);
    }

    _pageController = PageController(initialPage: _currentPage - 1);
    
    if (widget.initialAyah != null) {
      _activeAyah = widget.initialAyah;
      _tappedAyah = widget.initialAyah;
      _tappedSurah = widget.initialSurah;
      
      // 🌅 Handle Ayah of the Day Auto-Play
      if (widget.autoPlay) {
        // We'll trigger this in _initAsync or similar after UI is ready
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _activeAyah != null) {
            _handleAyahTap(widget.initialSurah ?? 1, _activeAyah!);
          }
        });
      }
    }
    
    // 📡 Initialize Collaborative Features
    _firebaseKhatma = Provider.of<FirebaseKhatmaService>(context, listen: false);
    if (widget.sharedKhatmaId != null) {
      _khatmaStream = _firebaseKhatma.streamKhatma(widget.sharedKhatmaId!);
      _firebaseKhatma.updatePresence(widget.sharedKhatmaId!, true);
    }

    _loadPageData(widget.initialPage);
    QuranPageHelper.preloadAyahPageMap(); // 🗺️ Build ayah→page map early
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
    _loadBookmarkedPages();
    _loadTajweedSetting(); // 🖌️ New for Phase 103
    _loadPageSliderSetting(); // 📜 New for Phase 115

    // Start UI idle timer ⏱️
    _resetIdleTimer();

    // Start session timer ⏱️
    _sessionStopwatch.start();
    _sessionTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final elapsed = _sessionStopwatch.elapsed;
        setState(() {
          _sessionTimeDisplay = '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });

    // Global audio listener removed to favor localized widget listener
  }

  // _initGlobalAudioListener() removed

  Future<void> _loadPageSliderSetting() async {
    final show = await SettingsService.getShowPageSlider();
    if (mounted) setState(() => _showPageSlider = show);
  }

  Future<void> _initWakelock() async {
    final keepScreenOn = await SettingsService.getKeepScreenOn();
    if (keepScreenOn) {
      WakelockPlus.enable();
    }
  }

  Future<void> _loadTajweedSetting() async {
    final show = await SettingsService.getShowTajweed();
    if (mounted) setState(() => _showTajweed = show);
  }

  Future<void> _loadBookmarkedPages() async {
    final pageBookmarks = await BookmarkService.getPageBookmarks();
    final pages = <int>{};
    for (final pb in pageBookmarks) {
      final pageNum = pb['pageNumber'] as int? ?? 0;
      if (pageNum > 0) {
        pages.add(pageNum);
      }
    }
    if (mounted) {
      setState(() => _bookmarkedPages = pages);
    }
  }

  Future<void> _handleAyahTap(int surah, int ayah) async {
    debugPrint('🎯 Tapped Ayah via Dynamic Renderer: $surah:$ayah');

    // 🚀 تأكيد إظهار الواجهة في حال كانت مخفية وتصفير المؤقت
    if (!_showBars) {
      _toggleFullscreen(forceHide: false);
    }
    _resetIdleTimer();

    setState(() {
      _selectedAyah = ayah;
      _selectedSurah = surah;
      _activeAyah = ayah; // To visually highlight it
      _activeSurah = surah; // 🎯 NEW: Set active surah on tap
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _handleAyahLongPress(int surah, int ayah) async {
    debugPrint('🎯 Long Pressed Ayah: $surah:$ayah');

    // Dismiss contextual top bar if it was open
    setState(() {
      _selectedAyah = null;
      _selectedSurah = null;
      _activeAyah = ayah;
    });

    HapticFeedback.mediumImpact();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.2),
        builder: (_) => Center(child: CircularProgressIndicator(color: _richGold)),
      );

      // 1. Fetch Translation (Background)
      final translation = await _quranService.getTranslation(surah, ayah, 131);
      
      // 2. Fetch Tafseer (Background) - Using Tafseer As-Sa'di for individual contemplations
      final tafseerData = await _quranService.getTafseer(surah, ayah, preferredTafseerId: 91);
      final tafseer = tafseerData['text'] ?? "لا يوجد تفسير متاح.";

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AyahInteractionBubble(
                surah: surah,
                ayah: ayah,
                translation: translation,
                tafseer: tafseer,
                fontSize: _translationFontSize,
                onPlay: () {
                  Navigator.pop(context);
                  setState(() {
                    _tappedAyah = ayah;
                    _tappedSurah = surah;
                  });
                },
                onClose: () => Navigator.pop(context),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading on error
      debugPrint('❌ Error fetching bubble data: $e');
    }
  }

  void _enterSanctuaryMode() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isSanctuaryMode = true;
      _showBars = false;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // 🔔 User left the app while reading. Schedule the "Rescue Call" smart nudges.
      SmartNotificationService.refreshSmartNudges();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 🔔 User closed the Mushaf. Schedule retention nudges.
    SmartNotificationService.refreshSmartNudges();
    
    _statsTimer?.cancel();
    _uiIdleTimer?.cancel();
    _pageController.dispose();
    _barAnimController.dispose();
    _pageTurnController.dispose();
    _sanctuaryController.dispose();

    // 📡 Leave Shared Khatma Session
    if (widget.sharedKhatmaId != null) {
      _firebaseKhatma.updatePresence(widget.sharedKhatmaId!, false);
    }

    // Stop session timer and save reading time ⏱️
    _sessionStopwatch.stop();
    _sessionTickTimer?.cancel();
    _globalAudioSub?.cancel();
    final minutes = _sessionStopwatch.elapsed.inMinutes;
    if (minutes > 0) {
      ReadingStatsService.recordSessionTime(minutes: minutes);
    }
    
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

  void _autoTurnToNextPage() {
    bool isLastPage = _currentPage >= 604;
    debugPrint('🔄 Auto-turn requested. Current Page: $_currentPage. Looping: $isLastPage');

    if (_pageController.hasClients) {
      setState(() => _isAudioContinuing = true); // 🚀 Set flag for seamless transition
      
      if (isLastPage) {
        // 🔄 Loop back to the beginning (Al-Fatihah, Page 1)
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    }

    if (mounted) {
      setState(() {
        _isAudioContinuing = true; // 🚀 Keep flag true for continuous play
        _tappedAyah = null; // Reset tapped Ayah to start from the page beginning
        if (isLastPage) _currentPage = 1; // Premptive state sync
      });
    }
  }

  void _resetIdleTimer() {
    _cancelIdleTimer();
    _uiIdleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _showBars && !_isSanctuaryMode && _selectedAyah == null) {
        _toggleFullscreen(forceHide: true);
      }
    });
  }

  void _cancelIdleTimer() {
    _uiIdleTimer?.cancel();
    _uiIdleTimer = null;
  }

  void _toggleFullscreen({bool? forceHide}) {
    setState(() {
      if (forceHide != null) {
        _showBars = !forceHide;
      } else {
        _showBars = !_showBars;
      }
    });
    
    if (_showBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _barAnimController.forward();
      _resetIdleTimer(); // ⏱️ Start countdown when shown
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _barAnimController.reverse();
      _cancelIdleTimer(); // ⏱️ Stop countdown when hidden
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final kidsMode = Provider.of<KidsModeService>(context);
    final isKids = kidsMode.isKidsModeActive;
    final bgColor = isKids ? kidsMode.backgroundColor : _deepGreen;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? _buildLoadingState()
          : GestureDetector(
              onTap: () => _toggleFullscreen(),
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
                  if (_isSanctuaryMode)
                    Positioned.fill(
                      key: const ValueKey('mushaf_sanctuary_overlay'),
                      child: _SanctuaryOverlay(
                        controller: _sanctuaryController,
                        onExit: _exitSanctuaryMode,
                      ),
                    ),



                  // === الشريط العلوي ===
                  _buildPremiumTopBar(isKids: isKids, kidsMode: kidsMode),

                  // === الشريط السفلي الموحد (المشغل) ===

                  // === 📜 Page Slider (Mini-map) ===
                  if (_showBars && _showPageSlider) _buildPreviewSlider(),

                  // === مشغل الصوت ===
                  Positioned(
                    key: const ValueKey('mushaf_audio_player_container'),
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showBars
                          ? MushafAudioPlayer(
                              theme: _currentTheme, // 🎨 Pass dynamic theme
                              pageNumber: _currentPage,
                              initialAyah: _tappedAyah,
                              initialSurah: _tappedSurah,
                              autoPlayContinues: _isAudioContinuing || _tappedAyah != null, // 🚀 NEW
                              autoPlayReciter: widget.autoPlayReciter,
                              onAyahChanged: (surah, ayah) {
                                if (mounted) {
                                  setState(() {
                                    _activeAyah = ayah;
                                    _activeSurah = surah;
                                    _selectedAyah = null;
                                    _highlightedWordLocation = null; 
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
                              onEndOfPage: () {
                                _autoTurnToNextPage();
                              },
                              onClose: () {
                                setState(() {
                                  _activeAyah = null;
                                  _highlightedWordLocation = null; // Reset
                                  _isAudioContinuing = false; // Reset
                                  _isMemorizationMode = false;
                                  _tappedAyah = null; // Reset tapped ayah
                                });
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
          

                  // === AI Buttons Removed for Minimalist Audio Experience ===


                  // === 📏 Premium Side Progress Rail ===
                  if (!_isSanctuaryMode)
                    _buildSideProgressRail(),
                ],
              ),
            ),
    );
  }


  Widget _buildSideProgressRail() {
    return Positioned(
      right: 4,
      top: 150,
      bottom: 150,
      child: Container(
        width: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Active Progress Line
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 4,
              height: (MediaQuery.of(context).size.height - 300) * (_currentPage / 604),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gold.withValues(alpha: 0.2), AppColors.gold],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Floating Star Marker
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              top: (MediaQuery.of(context).size.height - 300) * (_currentPage / 604) - 8,
              child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 16),
            ),
          ],
        ),
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

                    NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if ((notification is ScrollStartNotification || notification is ScrollUpdateNotification) && _showBars) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _showBars) _toggleFullscreen(forceHide: true);
                          });
                        }
                        return false;
                      },
                      child: Directionality(
                        key: const ValueKey('mushaf_page_view_wrapper'),
                        textDirection: TextDirection.rtl,
                        child: PageView.builder(
                          key: const PageStorageKey('mushaf_page_view'),
                        controller: _pageController,
                        physics: _isPageZoomed 
                          ? const NeverScrollableScrollPhysics() 
                          : const BouncingScrollPhysics(),
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
        
                          // Check if this was an auto-turn from the player bar
                          final bool wasAutoTurn = _isAudioContinuing;

                          setState(() {
                            _currentPage = page;
                            _currentSurahName = QuranPageHelper.getSurahNameForPage(page);
                            _currentJuz = QuranPageHelper.getJuzForPage(page);
                            
                            if (wasAutoTurn) {
                              // 🚀 Keep flag true so MushafAudioPlayer sees it in didUpdateWidget,
                              // then reset after the widget rebuild cycle completes
                              _tappedAyah = null;
                              _tappedSurah = null;
                            } else {
                              // Manual flip: reset everything
                              _isAudioContinuing = false; 
                              _tappedAyah = null; 
                              _tappedSurah = null;
                            }
                          });

                          // 🚀 Reset auto-turn flag AFTER the widget rebuild cycle
                          if (wasAutoTurn) {
                             Future.delayed(const Duration(milliseconds: 300), () {
                               if (mounted) setState(() => _isAudioContinuing = false);
                             });
                          }

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

                              return RepaintBoundary(
                                child: _buildPremiumPage(pageNumber),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    ),

                    // ظل الكعب على الصفحة
                    Positioned(
                      key: const ValueKey('mushaf_binding_shadow'),
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.15),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.05),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.15),
                              ],
                              stops: const [0.0, 0.48, 0.5, 0.52, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 📡 Live Presence Pulse (Phase 105)
                    if (_khatmaStream != null)
                      _buildLivePresencePulse(),

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

  Widget _buildLivePresencePulse() {
    return StreamBuilder<SharedKhatma>(
      stream: _khatmaStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final khatma = snapshot.data!;
        final onlineCount = khatma.onlineParticipants.length;
        if (onlineCount <= 1) return const SizedBox(); // Only show if others are there

        return Positioned(
          top: 70,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _richGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Pulse Dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.greenAccent, blurRadius: 4, spreadRadius: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'يقرأ الآن: $onlineCount',
                  style: GoogleFonts.amiri(
                    color: _richGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

          // Bookmark Ribbon Indicator 🔖✨
          if (_bookmarkedPages.contains(pageNumber))
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                width: 32,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _richGold,
                      _richGold.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _richGold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_rounded, color: Colors.white, size: 18),
                  ],
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
      highlightedSurah: _activeSurah ?? QuranPageHelper.getSurahForPage(pageNumber),
      highlightedAyah: _activeAyah,
      highlightedWordLocation: _highlightedWordLocation,
      isMemorizationMode: _isMemorizationMode,
      theme: _currentTheme,
      onAyahTapped: (surah, ayah) => _handleAyahTap(surah, ayah),
      onAyahLongPressed: (surah, ayah) => _handleAyahLongPress(surah, ayah),
      fontSize: _quranFontSize,
      fontFamily: _selectedFont,
      edition: _selectedEdition,
      showTajweed: _showTajweed,
      pageController: _pageController,
      onZoomChanged: (zoomed) {
        if (mounted && _isPageZoomed != zoomed) {
          setState(() => _isPageZoomed = zoomed);
        }
      },
    );
  }

  // ============================================================
  //  PREMIUM TOP BAR
  // ============================================================
  Widget _buildPremiumTopBar({bool isKids = false, KidsModeService? kidsMode}) {
    final primaryColor = isKids ? kidsMode?.primaryColor ?? _richGold : _richGold;
    final isAyahSelected = _selectedAyah != null && _selectedSurah != null;

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
                offset: Offset(0, -120 * (1 - _barSlideAnimation.value)), // 🚀 Increased offset to ensure it's fully hidden
                child: child,
              );
            },
            child: Directionality(
              textDirection: TextDirection.rtl, // 🎯 Force RTL to ensure consistent Arabic layout
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 5, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isAyahSelected 
                      ? [
                          _richGold.withValues(alpha: 0.95),
                          _darkGold.withValues(alpha: 0.90),
                        ]
                      : [
                          _deepGreen,
                          _deepGreen.withValues(alpha: 0.97),
                          _deepGreen.withValues(alpha: 0.85),
                        ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isAyahSelected ? Colors.transparent : _richGold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: isAyahSelected ? [
                    BoxShadow(color: _richGold.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: isAyahSelected 
                    ? _buildContextualTopBarItems() 
                    : _buildNormalTopBarItems(primaryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextualTopBarItems() {
    final surahName = QuranPageHelper.surahNames[_selectedSurah! - 1];

    return Row(
      children: [
        _PremiumIconButton(
          icon: Icons.close_rounded,
          color: _deepGreen,
          onPressed: () => setState(() {
            _selectedAyah = null;
            _selectedSurah = null;
          }),
        ),
        const SizedBox(width: 8),
        Text(
          "الآية $_selectedAyah",
          style: GoogleFonts.amiri(
            color: _deepGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        _PremiumIconButton(
          icon: Icons.play_arrow_rounded,
          color: _deepGreen,
          onPressed: () {
            setState(() {
              _tappedAyah = _selectedAyah;
              _tappedSurah = _selectedSurah;
              _selectedAyah = null;
              _selectedSurah = null;
            });
          },
        ),
        _PremiumIconButton(
          icon: Icons.notes_rounded, // Tafseer
          color: _deepGreen,
          onPressed: () => _handleAyahLongPress(_selectedSurah!, _selectedAyah!),
        ),
        _PremiumIconButton(
          icon: Icons.bookmark_add_rounded,
          color: _deepGreen,
          onPressed: () {
            BookmarkService.addBookmark(
              surahNumber: _selectedSurah!,
              ayahNumber: _selectedAyah!,
              surahName: surahName,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ تم حفظ الآية $_selectedAyah من سورة $surahName')),
            );
            setState(() {
              _selectedAyah = null;
              _selectedSurah = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNormalTopBarItems(Color primaryColor) {
    return Row(
      children: [
        // اليمين: زر الرجوع + معلومات السورة
        // اليمين: زر الرجوع (أيقونة الرئيسية) مع استايل بريميوم
        _HomeReturnButton(
          primaryColor: primaryColor,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // 🚀 If Mushaf was the root (Fast Startup), go to Dashboard
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
              );
            }
          },
        ),
        const SizedBox(width: 8),
        
        // معلومات السورة والجزء
        Flexible(
          child: GestureDetector(
            onTap: _showNavigationPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // 📏 More compact
              decoration: BoxDecoration(
                color: _richGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _richGold.withValues(alpha: 0.2), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gold, size: 12), // 📏 Reduced icon size
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _currentSurahName,
                            style: GoogleFonts.amiri(
                              color: primaryColor,
                              fontSize: 16, // 📏 More compact font
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          'جزء $_currentJuz',
                          style: GoogleFonts.amiri(
                            color: _lightGold.withValues(alpha: 0.6),
                            fontSize: 9, // 📏 More compact font
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8), // 🚀 Reduced gap for unified premium feel

        // اليسار: أدوات الوصول السريع مع تجنب الـ Overflow
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Session Timer ⏱️
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x14FFD700), // GOLD 8%
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0x99FFD700), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _sessionTimeDisplay,
                    style: GoogleFonts.outfit(
                      color: const Color(0xB3FFD700), // GOLD 70%
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            
            // زر الخيارات (يحتوي على باقي الأدوات لتوفير المساحة)
            _PremiumIconButton(
              icon: Icons.more_vert_rounded,
              onPressed: () => _showPageOptions(context, _currentPage),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  //  MINI-MAP SLIDER 📜✨
  // ============================================================
  Widget _buildPreviewSlider() {
    return Positioned(
      bottom: 85, // Above the bottom bar
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview Tooltip
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isScrubbing ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _deepGreen,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _richGold.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: _richGold.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'صفحة ${_previewPage ?? _currentPage} — ${QuranPageHelper.getSurahNameForPage(_previewPage ?? _currentPage)}',
                      style: GoogleFonts.amiri(
                        color: _richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Slider Track
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: _deepGreen.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _richGold.withValues(alpha: 0.3)),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl, // 1 to 604 R-to-L
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: _richGold,
                        inactiveTrackColor: _richGold.withValues(alpha: 0.2),
                        thumbColor: _parchment,
                        overlayColor: _richGold.withValues(alpha: 0.1),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      ),
                      child: Slider(
                        value: (_previewPage ?? _currentPage).toDouble(),
                        min: 1,
                        max: 604,
                        onChanged: (val) {
                          setState(() {
                            _isScrubbing = true;
                            _previewPage = val.toInt();
                          });
                        },
                        onChangeEnd: (val) {
                          setState(() {
                            _isScrubbing = false;
                            if (_previewPage != null && _previewPage != _currentPage) {
                              if (_pageController.hasClients) {
                                _pageController.jumpToPage(_previewPage! - 1);
                              }
                            }
                            _previewPage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        // Player is now integrated into the bottom bar
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
                  ],
                ),
                const SizedBox(height: 20),
                // الأزرار المخفية سابقاً لتوفير المساحة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPremiumOption(
                      icon: Icons.self_improvement_rounded,
                      label: 'محراب التلاوة',
                      onTap: () {
                        Navigator.pop(context);
                        _enterSanctuaryMode();
                      },
                    ),
                    _buildPremiumOption(
                      icon: _isVerticalMode ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
                      label: 'اتجاه القراءة',
                      onTap: () async {
                        Navigator.pop(context);
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
                    _buildPremiumOption(
                      icon: Icons.bookmark_add_rounded,
                      label: 'حفظ الصفحة',
                      onTap: () async {
                        await BookmarkService.addPageBookmark(pageNumber: pageNumber);
                        await _loadBookmarkedPages();
                        setModalState(() {}); // 🔄 Refresh modal list immediately
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حفظ الصفحة $pageNumber ✓',
                              style: GoogleFonts.amiri(color: Colors.white),
                            ),
                            backgroundColor: _deepGreen,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    _buildPremiumOption(
                      icon: _showPageSlider ? Icons.linear_scale_rounded : Icons.maximize_rounded,
                      label: 'مؤشر الصفحات',
                      onTap: () async {
                        Navigator.pop(context);
                        final newVal = !_showPageSlider;
                        setState(() => _showPageSlider = newVal);
                        await SettingsService.setShowPageSlider(newVal);
                        HapticFeedback.mediumImpact();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                
                // 🔖 Marks section integrated directly
                _buildMarksSection(setModalState),
              ],
            ),
          ),
        );
      },
    );
  },
);
}

  // 🔖 Integrated Marks Section inside Page Options
  Widget _buildMarksSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bookmarks_rounded, color: _richGold, size: 16),
            const SizedBox(width: 8),
            Text(
              'العلامات المرجعية',
              style: GoogleFonts.amiri(
                color: _richGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: BookmarkService.getPageBookmarks(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'لا توجد علامات مرجعية محفوظة 🔖',
                    style: GoogleFonts.amiri(color: Colors.white24, fontSize: 16),
                  ),
                ),
              );
            }

            final marks = snapshot.data!;
            return SizedBox(
              height: 90,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                itemCount: marks.length,
                itemBuilder: (context, index) {
                  final mark = marks[index];
                  final page = mark['pageNumber'] as int;
                  final surah = QuranPageHelper.getSurahNameForPage(page);
                  
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _richGold.withValues(alpha: 0.1)),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(page - 1);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  surah,
                                  style: GoogleFonts.amiri(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'صفحة $page',
                                  style: GoogleFonts.outfit(
                                    color: _richGold.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 14, color: Colors.white24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await BookmarkService.removePageBookmark(page);
                                await _loadBookmarkedPages();
                                setModalState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
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
  final Color? color;

  const _PremiumIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFD4A947);
    return IconButton(
      icon: Icon(icon, color: effectiveColor, size: 20),
      onPressed: onPressed,
      splashColor: effectiveColor.withValues(alpha: 0.15),
      highlightColor: effectiveColor.withValues(alpha: 0.05),
    );
  }
}

/// 🏡 زر العودة للصفحة الرئيسية بتصميم فخم (Glassmorphism)
class _HomeReturnButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color primaryColor;

  const _HomeReturnButton({required this.onPressed, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4), // 🚀 مسافة بسيطة عن الحافة
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12), // 🎨 شفافية هادئة
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
                child: Icon(
                  Icons.home_rounded, // 🏡 أيقونة الرئيسية بدلاً من سهم العودة
                  color: primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
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

// ============================================================
//  CUSTOM PAINTERS & WIDGETS (Phase 115)
// ============================================

