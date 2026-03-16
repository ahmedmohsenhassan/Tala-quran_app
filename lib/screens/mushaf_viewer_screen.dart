import 'dart:math' as math;
import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/mushaf_audio_player.dart';
import '../widgets/ai_tajweed_sheet.dart';
import '../services/recitation_recognition_service.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/khatma_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../services/ayah_sync_service.dart';
import '../services/reading_service.dart';
import '../models/ayah_coordinate.dart';
import '../widgets/ayah_highlighter.dart';
import 'tafseer_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/kids_mode_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

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
  String? _mushafDirPath;
  String _currentReading = ReadingService.hafs;
  bool _isDownloaded = false;
  bool _showBars = true;
  bool _isLoading = true;
  String _currentSurahName = '';
  int _currentJuz = 1;

  bool _isMemorizationMode = false;
  bool _isPeeking = false;

  // Highlighting state
  int? _activeAyah;
  List<AyahCoordinate> _pageCoordinates = [];
  List<AyahCoordinate> _activeAyahCoordinates = [];
  int? _tappedAyah; // New: to track specifically tapped ayah
  bool _isSanctuaryMode = false;
  
  // Optimization
  bool _pageFileExists = false;
  int _lastLoadId = 0; // Race condition protection
  Timer? _statsTimer;

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
  }

  void _handleAyahTap(Offset localPos, double width, double height) {
    if (_pageCoordinates.isEmpty) return;

    // Map screen tap to original coordinate system (1024 width base)
    final double scaleX = 1024 / width;
    final double scaleY = 1400 / height; // Assuming standard 1400 height for Medina Mushaf relative to 1024
    
    final double tappedX = localPos.dx * scaleX;
    final double tappedY = (localPos.dy - 30) * scaleY; // Adjusted for padding in _buildPremiumPage

    for (var coord in _pageCoordinates) {
      if (tappedX >= coord.minX && tappedX <= coord.maxX &&
          tappedY >= coord.minY && tappedY <= coord.maxY) {
        
        debugPrint('🎯 Tapped Ayah: ${coord.ayahNumber}');
        
        setState(() {
          _tappedAyah = coord.ayahNumber;
          _showAudioPlayer = true;
          _activeAyah = coord.ayahNumber;
          _activeAyahCoordinates = _pageCoordinates
              .where((c) => c.ayahNumber == coord.ayahNumber)
              .toList();
        });
        
        HapticFeedback.mediumImpact();
        return;
      }
    }
    
    // If we tap empty area, toggle bars
    _toggleFullscreen();
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

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getMushafTheme();
    if (mounted) {
      setState(() {
        _currentTheme = theme;
      });
    }
  }

  Future<void> _initMushafDir() async {
    final prefs = await SharedPreferences.getInstance();
    _currentReading = await ReadingService.getSelectedReading();

    final isDownloaded = prefs.getBool(
            'mushaf_downloaded_${_currentReading == ReadingService.hafs ? 'hafs' : 'warsh'}') ??
        (prefs.getBool('mushaf_downloaded') ?? false);

    if (isDownloaded) {
      final dir = await getApplicationDocumentsDirectory();
      final readingFolder = _currentReading == ReadingService.hafs
          ? 'mushaf_hafs'
          : 'mushaf_warsh';

      final oldDir = Directory('${dir.path}/mushaf_pages');
      final newDir = Directory('${dir.path}/$readingFolder');

      final finalPath = (await newDir.exists()) ? newDir.path : oldDir.path;

      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _mushafDirPath = finalPath;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _mushafDirPath = null;
        });
      }
    }
  }

  Future<void> _loadPageData(int pageNumber, {bool isBackground = false}) async {
    final currentLoadId = ++_lastLoadId;
    
    if (!isBackground) setState(() => _isLoading = true);
    await _initMushafDir();
    
    // Check if this request is still relevant
    if (currentLoadId != _lastLoadId) return;

    _currentSurahName = QuranPageHelper.getSurahNameForPage(pageNumber);
    _currentJuz = QuranPageHelper.getJuzForPage(pageNumber);

    final coords = await AyahSyncService().getPageCoordinates(pageNumber);
    
    // Check again after async gap
    if (currentLoadId != _lastLoadId) return;

    _pageCoordinates = coords;

    if (_isDownloaded && _mushafDirPath != null) {
      final file = File(
          '$_mushafDirPath/page${pageNumber.toString().padLeft(3, '0')}.png');
      _pageFileExists = await file.exists();
    } else {
      _pageFileExists = false;
    }

    if (!isBackground) setState(() => _isLoading = false);
    if (isBackground && mounted) {
      setState(() {
        // Refresh active coordinates if audio is already playing on this page
        if (_activeAyah != null) {
          _activeAyahCoordinates = _pageCoordinates
              .where((c) => c.ayahNumber == _activeAyah)
              .toList();
          debugPrint('📍 Coordinates refreshed for Ayah $_activeAyah: ${_activeAyahCoordinates.length} segments');
        }
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

  @override
  void dispose() {
    // Safety: dispose controllers
    _pageController.dispose();
    _barAnimController.dispose();
    _pageTurnController.dispose();

    // Reset UI mode safely after the current frame to avoid blocking the transition
    // especially important in "Run and Debug" mode to prevent platform channel deadlocks.
    Future.delayed(Duration.zero, () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
    
    super.dispose();
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
                                    _activeAyahCoordinates = _pageCoordinates
                                        .where((c) => c.ayahNumber == ayah)
                                        .toList();
                                  });
                                }
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
                                  _activeAyahCoordinates = [];
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
                              clipBehavior: Clip.none, // Essential for showing curl outside bounds
                              reverse: false, // Page 1 on right, Swipe R->L advances
                              itemCount: 604,
                              onPageChanged: (index) {
                                final page = index + 1;
                                
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
                                    if (pageOffset > 0 && pageOffset < 1) {
                                      // 1. Calculations for the curl geometry
                                      // angle: how much the page has flipped (0 to PI)
                                      angle = (pageOffset * math.pi).clamp(0.0, math.pi);
                                      
                                      // The curl progression (0 at start, 1 at middle, 0 at end)
                                      final double curlFactor = math.sin(pageOffset * math.pi);
                                      
                                      // Protrusion towards the face (Z-axis)
                                      final double zProtrusion = curlFactor * 140; 
                                      
                                      // 2. The Backface Logic
                                      // When angle > PI/2, we are seeing the reverse side of the paper
                                      final bool isBackFace = angle > (math.pi / 2);

                                      return Transform(
                                        alignment: Alignment.centerRight,
                                        transform: Matrix4.identity()
                                          ..setEntry(0, 3, pageOffset * MediaQuery.of(context).size.width) // Right Hinge Lock
                                          ..setEntry(3, 2, 0.0012) // Perspective
                                          ..setEntry(2, 3, zProtrusion) // Lift toward face
                                          ..rotateY(angle)
                                          // Dynamic Cylindrical Skew
                                          ..setEntry(1, 0, pageOffset * 0.15 * (isBackFace ? 1 : -1))
                                          ..rotateX(-pageOffset * 0.06),
                                        child: Stack(
                                          children: [
                                            // High-Contrast Contact Shadow on the static page
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

                                            // The actual page (Front/Back)
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
                                                            color: _parchmentDark, // Original Parchment Backhouse
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

                                                  // Sophisticated Cylindrical Shading
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
                                                            Colors.white.withValues(alpha: curlFactor * 0.35), // The Glint
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
                                    else if (pageOffset < 0) {
                                      // Next page underneath
                                      return _buildPremiumPage(pageNumber);
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
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 3.5,
        child: GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            _handleAyahTap(localPos, box.size.width, box.size.height);
          },
          onLongPress: () => _showPageOptions(context, pageNumber),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Page Content
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
                child: _buildPageImage(pageNumber),
              ),

              // Blur layer for memorization mode
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

              // Ornamental Frame
              IgnorePointer(
                child: CustomPaint(
                  painter: _OrnamentalFramePainter(
                    color: _richGold.withValues(alpha: 0.35),
                  ),
                ),
              ),

              // Dynamic Header & Footer
              _buildPageHeader(pageNumber),
              _buildPageFooter(pageNumber),

              // Highlight layer
              if (_currentPage == pageNumber &&
                  _activeAyah != null &&
                  _activeAyahCoordinates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
                  child: AyahHighlighter(
                    coordinates: _activeAyahCoordinates,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(int pageNumber) {
    final surahName = QuranPageHelper.getSurahNameForPage(pageNumber);
    final juzNumber = QuranPageHelper.getJuzForPage(pageNumber);

    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Juz Info with Decoration
          _OrnateHeader(
            text: 'الجزء $juzNumber',
            isLeft: true,
            color: _richGold,
          ),
          
          // Surah Name with Decoration
          _OrnateHeader(
            text: surahName,
            isLeft: false,
            color: _richGold,
          ),
        ],
      ),
    );
  }

  Widget _buildPageFooter(int pageNumber) {
    return Positioned(
      bottom: 2,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _richGold.withValues(alpha: 0.15), width: 0.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _FooterOrnamentPainter(color: _richGold.withValues(alpha: 0.4)),
                size: const Size(45, 45),
              ),
              Text(
                '$pageNumber',
                style: GoogleFonts.outfit(
                  color: _darkGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageImage(int pageNumber) {
    if (pageNumber <= 5) {
      return Image.asset(
        'assets/mushaf/page${pageNumber.toString().padLeft(3, '0')}.png',
        fit: BoxFit.fill,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildPremiumPlaceholder(pageNumber),
      );
    } else if (_isDownloaded && _mushafDirPath != null && _pageFileExists) {
      final file = File(
          '$_mushafDirPath/page${pageNumber.toString().padLeft(3, '0')}.png');
      return Image.file(
        file,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _buildPremiumPlaceholder(pageNumber),
      );
    }
    return _buildPremiumPlaceholder(pageNumber);
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
                  // زر وضع محراب التلاوة
                  _PremiumIconButton(
                    icon: Icons.self_improvement_rounded,
                    onPressed: _enterSanctuaryMode,
                  ),
                  const SizedBox(width: 8),
                  
                  // زر الرجوع
                  _PremiumIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  const Spacer(),

                  // معلومات السورة والجزء
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // زخرفة علوية صغيرة
                      _MiniOrnament(color: _richGold.withValues(alpha: 0.4)),
                      const SizedBox(height: 2),
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
                      Text(
                        'الجزء $_currentJuz',
                        style: GoogleFonts.amiri(
                          color: _lightGold.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _MiniOrnament(color: _richGold.withValues(alpha: 0.4)),
                    ],
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
  //  PREMIUM PLACEHOLDER
  // ============================================================
  Widget _buildPremiumPlaceholder(int pageNumber) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_parchment, _parchmentDark, _parchment],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زخرفة علوية
            CustomPaint(
              size: const Size(200, 30),
              painter: _OrnamentLinePainter(color: _richGold.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 30),
            Icon(
              Icons.menu_book_rounded,
              size: 80,
              color: _deepGreen.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'صفحة $pageNumber',
              style: GoogleFonts.amiri(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _deepGreen.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'حمّل الصفحات لقراءة المصحف كاملاً',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: _deepGreen.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            CustomPaint(
              size: const Size(200, 30),
              painter: _OrnamentLinePainter(color: _richGold.withValues(alpha: 0.3)),
            ),
          ],
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
                      icon: Icons.swap_horiz_rounded,
                      label: _currentReading == ReadingService.hafs
                          ? 'رواية ورش'
                          : 'رواية حفص',
                      onTap: () async {
                        Navigator.pop(context);
                        final nextReading =
                            _currentReading == ReadingService.hafs
                                ? ReadingService.warsh
                                : ReadingService.hafs;
                        await ReadingService.setSelectedReading(nextReading);
                        await _loadPageData(_currentPage);
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

/// إطار زخرفي إسلامي حول الصفحة
class _OrnamentalFramePainter extends CustomPainter {
  final Color color;
  _OrnamentalFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Main Outer Border
    final outerRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRRect(RRect.fromRectAndRadius(outerRect, const Radius.circular(2)), paint);

    // Thick frame area
    final thickFramePaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    final innerRect = Rect.fromLTWH(18, 18, size.width - 36, size.height - 36);
    
    // Draw the "frame" body
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(outerRect),
        Path()..addRect(innerRect),
      ),
      thickFramePaint,
    );

    // Inner Border
    canvas.drawRect(innerRect, paint..strokeWidth = 0.5);

    // Ornaments in corners
    _drawCorners(canvas, size, color);
    _drawSideOrnaments(canvas, size, color);
  }

  void _drawCorners(Canvas canvas, Size size, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const s = 25.0; // Corner size
    const margin = 8.0;

    // TL
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + s, margin), p);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + s), p);
    // TR
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - s, margin), p);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + s), p);
    // BL
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + s, size.height - margin), p);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - s), p);
    // BR
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - s, size.height - margin), p);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - s), p);
  }

  void _drawSideOrnaments(Canvas canvas, Size size, Color color) {
    final p = Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 0.5;
    // Tiny dots/diamonds along the frame
    for (double i = 40; i < size.height - 40; i += 60) {
      canvas.drawCircle(Offset(13, i), 1, p);
      canvas.drawCircle(Offset(size.width - 13, i), 1, p);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentalFramePainter oldDelegate) =>
      oldDelegate.color != color;
}


class _FooterOrnamentPainter extends CustomPainter {
  final Color color;
  _FooterOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Draw 8 stylized arcs for a floral look
    for (int i = 0; i < 8; i++) {
      final angle = i * 45 * 3.14 / 180;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      
      // Draw a small decorative arc/leaf
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r - 10, 0), radius: 6),
        -1.5,
        3.0,
        false,
        paint,
      );
      
      canvas.restore();
    }
    
    // Outer intricate shell
    final shellPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
      
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final offset = Offset(math.cos(angle) * (r - 2), math.sin(angle) * (r - 2));
      canvas.drawCircle(center + offset, 4, shellPaint);
    }
    
    // Inner circles
    canvas.drawCircle(center, r - 5, paint..strokeWidth = 0.6);
    canvas.drawCircle(center, r - 8, paint..strokeWidth = 0.3);
    
    // Core dots
    for (int i = 0; i < 4; i++) {
       final angle = (i * math.pi / 2);
       final dotOffset = Offset(math.cos(angle) * 11, math.sin(angle) * 11);
       canvas.drawCircle(center + dotOffset, 1, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Ornate Header Widget for Surah/Juz info
class _OrnateHeader extends StatelessWidget {
  final String text;
  final bool isLeft;
  final Color color;

  const _OrnateHeader({
    required this.text,
    required this.isLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLeft) _HeaderOrnament(color: color, flip: true),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.amiri(
              color: color.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLeft) _HeaderOrnament(color: color, flip: false),
        ],
      ),
    );
  }
}

class _HeaderOrnament extends StatelessWidget {
  final Color color;
  final bool flip;
  const _HeaderOrnament({required this.color, required this.flip});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip ? -1 : 1,
      child: CustomPaint(
        size: const Size(24, 12),
        painter: _HeaderOrnamentPainter(color: color),
      ),
    );
  }
}

class _HeaderOrnamentPainter extends CustomPainter {
  final Color color;
  _HeaderOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    // Intricate Islamic curve
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width * 0.4, 0, size.width * 0.8, size.height / 2);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.7, size.width, size.height / 2);
    path.moveTo(size.width * 0.2, size.height / 2);
    path.lineTo(size.width * 0.6, size.height / 2);
    
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height / 2), 1.5, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// خط زخرفي أفقي
class _OrnamentLinePainter extends CustomPainter {
  final Color color;
  _OrnamentLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final y = size.height / 2;
    // خط رئيسي
    canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), paint);
    // ماسة صغيرة في المنتصف
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx, y - 5)
      ..lineTo(cx + 5, y)
      ..lineTo(cx, y + 5)
      ..lineTo(cx - 5, y)
      ..close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
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

/// زخرفة علوية مصغرة
class _MiniOrnament extends StatelessWidget {
  final Color color;
  const _MiniOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 20, height: 1, color: color),
        const SizedBox(width: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Container(width: 20, height: 1, color: color),
      ],
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

