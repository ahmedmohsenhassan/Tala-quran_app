import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/mushaf_audio_player.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/reading_stats_service.dart';
import '../services/khatma_service.dart';
import '../utils/quran_page_helper.dart';
import '../services/ayah_sync_service.dart';
import '../services/reading_service.dart';
import '../models/ayah_coordinate.dart';
import '../widgets/ayah_highlighter.dart';
import 'tafseer_screen.dart';

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

  // Highlighting state
  int? _activeAyah;
  List<AyahCoordinate> _pageCoordinates = [];
  List<AyahCoordinate> _activeAyahCoordinates = [];

  // Optimization
  bool _pageFileExists = false;
  Timer? _statsTimer;

  // Animation controllers for premium effects
  late AnimationController _barAnimController;
  late Animation<double> _barSlideAnimation;

  // Page turning shadow animation
  late AnimationController _pageTurnController;

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

  Future<void> _loadPageData(int pageNumber) async {
    setState(() => _isLoading = true);
    await _initMushafDir();
    _currentSurahName = QuranPageHelper.getSurahNameForPage(pageNumber);
    _currentJuz = QuranPageHelper.getJuzForPage(pageNumber);

    _pageCoordinates = await AyahSyncService().getPageCoordinates(pageNumber);

    if (_isDownloaded && _mushafDirPath != null) {
      final file = File(
          '$_mushafDirPath/page${pageNumber.toString().padLeft(3, '0')}.png');
      _pageFileExists = await file.exists();
    } else {
      _pageFileExists = false;
    }

    setState(() => _isLoading = false);
  }

  void _recordPageVisit(int page) {
    _statsTimer?.cancel();
    _statsTimer = Timer(const Duration(seconds: 1), () {
      BookmarkService.saveLastRead(
        surahNumber: 0,
        surahName: 'المصحف',
        pageNumber: page,
      );
      StreakService.recordReading();
      ReadingStatsService.recordSession();
      KhatmaService.recordPage();
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
    _statsTimer?.cancel();
    _pageController.dispose();
    _barAnimController.dispose();
    _pageTurnController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ============================================================
  //  PREMIUM COLORS
  // ============================================================
  static const Color _deepGreen = Color(0xFF0B3B2D);
  static const Color _richGold = Color(0xFFD4A947);
  static const Color _lightGold = Color(0xFFE8C76A);
  static const Color _darkGold = Color(0xFFB8860B);
  static const Color _parchment = Color(0xFFFDF5E6);
  static const Color _parchmentDark = Color(0xFFF5E6C8);
  static const Color _spineColor = Color(0xFF062218);
  static const Color _pageShadow = Color(0x33000000);

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepGreen,
      body: _isLoading
          ? _buildLoadingState()
          : GestureDetector(
              onTap: _toggleFullscreen,
              child: Stack(
                children: [
                  // === الخلفية المزخرفة ===
                  const Positioned.fill(child: _PremiumBackground()),

                  // === إطار المصحف الخارجي ===
                  Positioned.fill(
                    child: _buildBookFrame(),
                  ),

                  // === الشريط العلوي ===
                  _buildPremiumTopBar(),

                  // === الشريط السفلي ===
                  _buildPremiumBottomBar(),

                  // === مشغل الصوت ===
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showAudioPlayer
                          ? MushafAudioPlayer(
                              key: const ValueKey('mushaf_audio_player'),
                              pageNumber: _currentPage,
                              onAyahChanged: (surah, ayah) {
                                setState(() {
                                  _activeAyah = ayah;
                                  _activeAyahCoordinates = _pageCoordinates
                                      .where((c) =>
                                          c.surahNumber == surah &&
                                          c.ayahNumber == ayah)
                                      .toList();
                                });
                              },
                              onClose: () {
                                setState(() {
                                  _showAudioPlayer = false;
                                  _activeAyah = null;
                                  _activeAyahCoordinates = [];
                                });
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
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
            child: const CircularProgressIndicator(
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
        // مساحة علوية للبار
        SizedBox(height: MediaQuery.of(context).padding.top + 56),

        // المصحف نفسه
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Container(
              decoration: BoxDecoration(
                // ظل خارجي للكتاب
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                child: Row(
                  children: [
                    // === العمود الأيمن: الكعب (Spine) ===
                    _buildSpine(),

                    // === منطقة الصفحات ===
                    Expanded(
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
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    _parchmentDark,
                                    _parchment,
                                    _parchment,
                                    _parchmentDark,
                                  ],
                                  stops: [0.0, 0.05, 0.95, 1.0],
                                ),
                              ),
                            ),

                            // PageView
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: 604,
                                onPageChanged: (index) {
                                  final page = index + 1;
                                  setState(() {
                                    _currentPage = page;
                                    _currentSurahName =
                                        QuranPageHelper.getSurahNameForPage(
                                            page);
                                    _currentJuz =
                                        QuranPageHelper.getJuzForPage(page);
                                    if (_showAudioPlayer) {
                                      _showAudioPlayer = false;
                                    }
                                  });
                                  _recordPageVisit(page);
                                  // Trigger subtle page turn effect
                                  _pageTurnController.forward(from: 0);
                                },
                                itemBuilder: (context, index) {
                                  final pageNumber = index + 1;
                                  return RepaintBoundary(
                                    child: _buildPremiumPage(pageNumber),
                                  );
                                },
                              ),
                            ),

                            // ظل الكعب على الصفحة
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: 20,
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
                                  margin: const EdgeInsets.all(3),
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
                  ],
                ),
              ),
            ),
          ),
        ),

        // مساحة سفلية للبار
        const SizedBox(height: 60),
      ],
    );
  }

  // ============================================================
  //  SPINE — الكعب
  // ============================================================
  Widget _buildSpine() {
    return Container(
      width: 18,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _spineColor,
            _deepGreen.withValues(alpha: 0.9),
            _deepGreen,
          ],
        ),
        border: Border(
          right: BorderSide(
            color: _darkGold.withValues(alpha: 0.5),
            width: 1.5,
          ),
          left: BorderSide(
            color: _darkGold.withValues(alpha: 0.7),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // زخرفة ذهبية على الكعب
          _SpineOrnament(color: _richGold.withValues(alpha: 0.6)),
          const SizedBox(height: 30),
          // نص عمودي
          RotatedBox(
            quarterTurns: 1,
            child: Text(
              'القرآن الكريم',
              style: GoogleFonts.amiri(
                color: _richGold.withValues(alpha: 0.8),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
          _SpineOrnament(color: _richGold.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  // ============================================================
  //  PREMIUM PAGE — الصفحة المزخرفة
  // ============================================================
  Widget _buildPremiumPage(int pageNumber) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 3.5,
      child: GestureDetector(
        onLongPress: () => _showPageOptions(context, pageNumber),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // محتوى الصفحة
            _buildPageImage(pageNumber),

            // إطار زخرفي عتيق حول المحتوي
            IgnorePointer(
              child: CustomPaint(
                painter: _OrnamentalFramePainter(
                  color: _richGold.withValues(alpha: 0.25),
                ),
              ),
            ),

            // Highlight layer
            if (_currentPage == pageNumber &&
                _activeAyah != null &&
                _activeAyahCoordinates.isNotEmpty)
              AyahHighlighter(
                coordinates: _activeAyahCoordinates,
              ),
          ],
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
  Widget _buildPremiumTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _barSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -60 * (1 - _barSlideAnimation.value)),
            child: Opacity(
              opacity: _barSlideAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            bottom: 8,
            left: 8,
            right: 8,
          ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              // زر الرجوع
              _PremiumIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  Navigator.pop(context);
                },
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
                      color: _richGold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: _richGold.withValues(alpha: 0.3),
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
    );
  }

  // ============================================================
  //  PREMIUM BOTTOM BAR
  // ============================================================
  Widget _buildPremiumBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _barSlideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 60 * (1 - _barSlideAnimation.value)),
            child: Opacity(
              opacity: _barSlideAnimation.value,
              child: child,
            ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                    color: _richGold,
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

              // زر الحفظ
              _PremiumIconButton(
                icon: Icons.bookmark_border_rounded,
                size: 22,
                onPressed: () async {
                  await BookmarkService.addPageBookmark(
                      pageNumber: _currentPage);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم حفظ الصفحة $_currentPage ✓',
                          style: GoogleFonts.amiri(color: Colors.white),
                        ),
                        backgroundColor: _deepGreen,
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
    );
  }

  // ============================================================
  //  PREMIUM PLACEHOLDER
  // ============================================================
  Widget _buildPremiumPlaceholder(int pageNumber) {
    return Container(
      decoration: const BoxDecoration(
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
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A3326),
          Color(0xFF062218),
          Color(0xFF041A12),
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
      ..strokeWidth = 0.8;

    // إطار خارجي
    final outerRect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRect(outerRect, paint);

    // إطار داخلي
    final innerRect = Rect.fromLTWH(14, 14, size.width - 28, size.height - 28);
    canvas.drawRect(innerRect, paint..strokeWidth = 0.4);

    // زخرفة الزوايا
    const cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // أعلى يسار
    canvas.drawLine(const Offset(8, 8), const Offset(8 + cornerSize, 8), cornerPaint);
    canvas.drawLine(const Offset(8, 8), const Offset(8, 8 + cornerSize), cornerPaint);
    // أعلى يمين
    canvas.drawLine(Offset(size.width - 8, 8),
        Offset(size.width - 8 - cornerSize, 8), cornerPaint);
    canvas.drawLine(Offset(size.width - 8, 8),
        Offset(size.width - 8, 8 + cornerSize), cornerPaint);
    // أسفل يسار
    canvas.drawLine(Offset(8, size.height - 8),
        Offset(8 + cornerSize, size.height - 8), cornerPaint);
    canvas.drawLine(Offset(8, size.height - 8),
        Offset(8, size.height - 8 - cornerSize), cornerPaint);
    // أسفل يمين
    canvas.drawLine(Offset(size.width - 8, size.height - 8),
        Offset(size.width - 8 - cornerSize, size.height - 8), cornerPaint);
    canvas.drawLine(Offset(size.width - 8, size.height - 8),
        Offset(size.width - 8, size.height - 8 - cornerSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _OrnamentalFramePainter oldDelegate) =>
      oldDelegate.color != color;
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

/// زخرفة الكعب
class _SpineOrnament extends StatelessWidget {
  final Color color;
  const _SpineOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 10, height: 1, color: color),
        const SizedBox(height: 3),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Container(width: 10, height: 1, color: color),
      ],
    );
  }
}
