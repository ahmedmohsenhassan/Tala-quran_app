import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Services
import '../services/firebase_khatma_service.dart';
import '../services/bookmark_service.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../services/audio_service.dart';

// Utils
import '../utils/quran_page_helper.dart';

// Widgets
import '../widgets/mushaf_page_renderer.dart';
import '../widgets/mushaf_navigation_picker.dart';
import '../widgets/mushaf/mushaf_top_bar.dart';
import '../widgets/mushaf/mushaf_bottom_player.dart';
import '../widgets/mushaf/mushaf_overlays.dart';
import '../widgets/mushaf/mushaf_ui_helpers.dart';

// Screens
import 'tafseer_screen.dart';
import 'main_dashboard_screen.dart';

/// 📖 عارض المصحف الاحترافي - Premium Mushaf Viewer
class MushafViewerScreen extends StatefulWidget {
  final int initialPage;
  final int? initialAyah;
  final int? initialSurah;
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
  
  // -- State Logic Variables --
  late PageController _pageController;
  int _currentPage = 1;
  bool _showBars = true;
  bool _isLoading = true;
  String _currentSurahName = '';
  int _currentJuz = 1;
  
  bool _isMemorizationMode = false;
  bool _isPeeking = false;

  int? _activeAyah;
  int? _activeSurah;
  int? _tappedAyah;
  int? _tappedSurah;
  String? _highlightedWordLocation;
  bool _isSanctuaryMode = false;
  
  Timer? _statsTimer;
  Timer? _uiIdleTimer;

  double _quranFontSize = 24.0;
  String _selectedFont = ThemeService.fontAmiri;
  String _selectedEdition = ThemeService.editionMadina1405;

  int? _selectedAyah; 
  int? _selectedSurah;

  bool _isAudioContinuing = false;
  bool _isAutoTurningPage = false;

  late AnimationController _barAnimController;
  late Animation<double> _barSlideAnimation;
  late AnimationController _sanctuaryController;

  bool _isPageZoomed = false;
  bool _showTajweed = false;
  late final FirebaseKhatmaService _firebaseKhatma;

  final Stopwatch _sessionStopwatch = Stopwatch();
  Timer? _sessionTickTimer;
  String _sessionTimeDisplay = '00:00';
  Set<int> _bookmarkedPages = {};
  StreamSubscription? _playbackSub;

  // -- Theme Helpers --
  String _currentTheme = ThemeService.mushafClassic;
  Color get _deepGreen => ThemeService.getMushafDeepGreen(_currentTheme);
  Color get _richGold => ThemeService.getMushafRichGold(_currentTheme);
  Color get _lightGold => _richGold.withValues(alpha: 0.8);
  Color get _darkGold => _richGold.withValues(alpha: 1.2);
  Color get _parchment => ThemeService.getMushafParchment(_currentTheme);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _currentPage = widget.initialPage;
    if (widget.initialSurah != null) {
      _currentPage = QuranPageHelper.getPageForSurah(widget.initialSurah!);
    }

    _pageController = PageController(initialPage: _currentPage - 1);
    
    // Initial Ayah highlighting
    if (widget.initialAyah != null) {
      _activeAyah = widget.initialAyah;
      _tappedAyah = widget.initialAyah;
      _tappedSurah = widget.initialSurah;
    }

    // Animations
    _barAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _barSlideAnimation = CurvedAnimation(parent: _barAnimController, curve: Curves.easeInOutCubic);
    _sanctuaryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

    _initAsync();
  }

  Future<void> _initAsync() async {
    _sessionStopwatch.start();
    _startSessionTimer();
    
    // Services
    _firebaseKhatma = FirebaseKhatmaService();
    if (widget.sharedKhatmaId != null) {
      _firebaseKhatma.joinKhatma(widget.sharedKhatmaId!);
    }

    await _loadSettings();
    await _loadBookmarkedPages();
    _loadPageData(_currentPage);
    _resetIdleTimer();
    _initPlaybackListener();
    
    if (mounted) setState(() => _isLoading = false);
    WakelockPlus.enable();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getMushafSettings();
    if (mounted) {
      setState(() {
        _currentTheme = settings['theme'];
        _quranFontSize = settings['fontSize'];
        _selectedFont = settings['font'];
        _selectedEdition = settings['edition'];
        _showTajweed = settings['showTajweed'];
      });
    }
  }

  void _loadPageData(int page, {bool isBackground = false}) {
    if (!isBackground) {
      setState(() {
        _currentSurahName = QuranPageHelper.getSurahNameForPage(page);
        _currentJuz = QuranPageHelper.getJuzForPage(page);
      });
    }
    BookmarkService.saveLastRead(
      pageNumber: page,
      surahNumber: QuranPageHelper.getSurahForPage(page),
      surahName: QuranPageHelper.getSurahNameForPage(page),
    );
  }

  void _startSessionTimer() {
    _sessionTickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        final duration = _sessionStopwatch.elapsed;
        setState(() {
          _sessionTimeDisplay = '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
        });
      }
    });
  }

  void _resetIdleTimer() {
    _uiIdleTimer?.cancel();
    if (_showBars && !_isSanctuaryMode) {
      _uiIdleTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _showBars) {
          setState(() {
            _showBars = false;
            _barAnimController.reverse();
          });
        }
      });
    }
  }

  Future<void> _loadBookmarkedPages() async {
    final bookmarks = await BookmarkService.getPageBookmarks();
    if (mounted) {
      setState(() {
        _bookmarkedPages = bookmarks.map((e) => e['pageNumber'] as int).toSet();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _barAnimController.dispose();
    _sanctuaryController.dispose();
    _sessionTickTimer?.cancel();
    _uiIdleTimer?.cancel();
    _statsTimer?.cancel();
    if (widget.sharedKhatmaId != null) _firebaseKhatma.leaveKhatma(widget.sharedKhatmaId!);
    WakelockPlus.disable();
    super.dispose();
  }

  // -- Interaction Handlers --

  void _handleAyahTap(int surah, int ayah) {
    _resetIdleTimer();
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedAyah == ayah && _selectedSurah == surah) {
        _selectedAyah = null;
        _selectedSurah = null;
      } else {
        _selectedAyah = ayah;
        _selectedSurah = surah;
      }
    });
  }

  void _handleAyahLongPress(int surah, int ayah) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafseerScreen(surahNumber: surah, ayahNumber: ayah),
      ),
    );
  }

  void _toggleBars() {
    if (_isPageZoomed) return;
    setState(() {
      _showBars = !_showBars;
      _showBars ? _barAnimController.forward() : _barAnimController.reverse();
    });
    _resetIdleTimer();
  }

  void _enterSanctuaryMode() {
    setState(() {
      _isSanctuaryMode = true;
      _showBars = false;
      _barAnimController.reverse();
    });
    _sanctuaryController.repeat(reverse: true);
    HapticFeedback.heavyImpact();
  }

  void _exitSanctuaryMode() {
    setState(() {
      _isSanctuaryMode = false;
      _showBars = true;
      _barAnimController.forward();
    });
    _sanctuaryController.stop();
    HapticFeedback.mediumImpact();
  }

  void _autoTurnToNextPage() {
    if (_isAutoTurningPage) return;
    _isAutoTurningPage = true;
    setState(() => _isAudioContinuing = true);
    
    final nextPage = (_currentPage % 604);
    _pageController.animateToPage(
      nextPage, 
      duration: const Duration(milliseconds: 1200), 
      curve: Curves.easeInOutCubic
    ).then((_) => _isAutoTurningPage = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF031E17), body: Center(child: CircularProgressIndicator()));


    return Scaffold(
      backgroundColor: _deepGreen,
      body: Stack(
        children: [
          const MushafPremiumBackground(),
          
          GestureDetector(
            onTap: _toggleBars,
            child: PageView.builder(
              controller: _pageController,
              reverse: true,
              onPageChanged: (p) {
                setState(() => _currentPage = p + 1);
                _loadPageData(_currentPage);
                _resetIdleTimer();
              },
              itemBuilder: (context, index) => _buildPage(index + 1),
            ),
          ),

          // Overlays & UI
          if (_isSanctuaryMode)
            MushafSanctuaryOverlay(controller: _sanctuaryController, onExit: _exitSanctuaryMode),

          MushafTopBar(
            isSanctuaryMode: _isSanctuaryMode,
            slideAnimation: _barSlideAnimation,
            selectedAyah: _selectedAyah,
            selectedSurah: _selectedSurah,
            currentSurahName: _currentSurahName,
            currentJuz: _currentJuz,
            sessionTimeDisplay: _sessionTimeDisplay,
            deepGreen: _deepGreen,
            richGold: _richGold,
            darkGold: _darkGold,
            lightGold: _lightGold,
            onCloseSelection: () => setState(() => _selectedAyah = _selectedSurah = null),
            onPlayAyah: () => setState(() { _tappedAyah = _selectedAyah; _tappedSurah = _selectedSurah; _selectedAyah = _selectedSurah = null; }),
            onTafseer: () => _handleAyahLongPress(_selectedSurah!, _selectedAyah!),
            onBookmarkAyah: () {
              BookmarkService.addBookmark(
                surahNumber: _selectedSurah!,
                ayahNumber: _selectedAyah!,
                surahName: QuranPageHelper.surahNames[_selectedSurah! - 1],
              );
              setState(() => _selectedAyah = _selectedSurah = null);
            },
            onShowNavigation: _showNavigationPicker,
            onHomePressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainDashboardScreen()));
              }
            },
            onShowOptions: (ctx) => _showPageOptions(ctx),
          ),

          MushafBottomPlayer(
            showBars: _showBars,
            slideAnimation: _barSlideAnimation,
            theme: _currentTheme,
            pageNumber: _currentPage,
            tappedAyah: _tappedAyah,
            tappedSurah: _tappedSurah,
            isAudioContinuing: _isAudioContinuing,
            autoPlayReciter: widget.autoPlayReciter,
            onAyahChanged: (s, a) => setState(() { _activeAyah = a; _activeSurah = s; }),
            onWordChanged: (loc) => setState(() => _highlightedWordLocation = loc),
            onMemorizationModeChanged: (m) => setState(() => _isMemorizationMode = m),
            onEndOfPage: _autoTurnToNextPage,
            onClose: () => setState(() { _activeAyah = null; _isAudioContinuing = false; _tappedAyah = null; }),
          ),

          if (!_isSanctuaryMode)
            MushafSideProgressRail(currentPage: _currentPage, screenHeight: MediaQuery.of(context).size.height),
        ],
      ),
    );
  }

  Widget _buildPage(int pageNumber) {
    return Container(
      color: _parchment,
      child: Stack(
        children: [
          MushafPageRenderer(
            pageNumber: pageNumber,
            highlightedSurah: _activeSurah ?? QuranPageHelper.getSurahForPage(pageNumber),
            highlightedAyah: _activeAyah,
            highlightedWordLocation: _highlightedWordLocation,
            isMemorizationMode: _isMemorizationMode,
            theme: _currentTheme,
            onAyahTapped: _handleAyahTap,
            onAyahLongPressed: _handleAyahLongPress,
            fontSize: _quranFontSize,
            fontFamily: _selectedFont,
            edition: _selectedEdition,
            showTajweed: _showTajweed,
            pageController: _pageController,
            onZoomChanged: (z) => setState(() => _isPageZoomed = z),
          ),
          
          if (_isMemorizationMode && !_isPeeking)
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => setState(() => _isPeeking = true),
                onPointerUp: (_) => setState(() => _isPeeking = false),
                behavior: HitTestBehavior.opaque,
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.white.withValues(alpha: 0.05))),
              ),
            ),

          if (_bookmarkedPages.contains(pageNumber))
            Positioned(
              top: 0, right: 16,
              child: Container(
                width: 32, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_richGold, _richGold.withValues(alpha: 0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
                ),
                child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  void _showNavigationPicker() async {
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
    if (result != null) _navigateToAyah(result['surah']!, result['ayah']!);
  }

  void _navigateToAyah(int surah, int ayah) {
    int targetPage = QuranPageHelper.getPageForSurah(surah);
    _pageController.jumpToPage(targetPage - 1);
    setState(() { _currentPage = targetPage; _activeAyah = ayah; });
  }

  void _showPageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _deepGreen, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('خيارات الصفحة $_currentPage', style: GoogleFonts.amiri(color: _richGold, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MushafPremiumOption(icon: Icons.notes_rounded, label: 'التفسير', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TafseerScreen(surahNumber: QuranPageHelper.getSurahForPage(_currentPage), ayahNumber: 1))), goldColor: _richGold, lightGoldColor: _lightGold),
                MushafPremiumOption(icon: Icons.self_improvement_rounded, label: 'المحراب', onTap: () { Navigator.pop(context); _enterSanctuaryMode(); }, goldColor: _richGold, lightGoldColor: _lightGold),
                MushafPremiumOption(icon: Icons.bookmark_add_rounded, label: 'حفظ', onTap: () async { await BookmarkService.addPageBookmark(pageNumber: _currentPage); _loadBookmarkedPages(); if (context.mounted) Navigator.pop(context); }, goldColor: _richGold, lightGoldColor: _lightGold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _initPlaybackListener() {
    _playbackSub?.cancel();
    _playbackSub = AudioService().ayahPlaybackStream.listen((state) {
      if (state == null || !state.isPlaying) return;
      
      // 🎯 Auto-Sync Page: If the audio has moved to a new page (e.g., in background or during continuous play)
      if (state.page != _currentPage && !_isAutoTurningPage) {
        debugPrint('🎨 [MushafViewer] Syncing page with audio: ${state.page}');
        if (!mounted) return;
        
        setState(() {
          _isAutoTurningPage = true;
          _currentPage = state.page;
        });

        _pageController.animateToPage(
          state.page - 1,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        ).then((_) {
          if (mounted) setState(() => _isAutoTurningPage = false);
        });
      }
    });
  }
}
