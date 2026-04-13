import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tala_quran_app/screens/main_dashboard_screen.dart';
import 'package:tala_quran_app/screens/mushaf_viewer_screen.dart';
import '../utils/app_colors.dart';
import '../services/bookmark_service.dart';
import '../services/reading_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/daily_verse_service.dart';
import '../services/streak_service.dart';
import '../services/reading_stats_service.dart';
import '../services/achievement_service.dart';

// ============================================================
//  Premium Colors for Splash
// ============================================================
const Color _kDeepGreen = Color(0xFF0A3326);
const Color _kCoverGreen = Color(0xFF0D4B3A);
const Color _kCoverDark = Color(0xFF072E22);
const Color _kRichGold = Color(0xFFD4A947);
const Color _kLightGold = Color(0xFFE8C76A);
const Color _kDarkGold = Color(0xFFB8860B);
const Color _kParchment = Color(0xFFFDF5E6);
const Color _kParchmentDark = Color(0xFFF5E6C8);

/// شاشة البداية الاحترافية — Premium Quran-Opening Splash
/// مصحف ثلاثي الأبعاد واقعي يفتح ببطء كأنك تفتح مصحف حقيقي
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1: Logo fade-in
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Phase 2: Book zoom-in from far
  late AnimationController _bookZoomController;
  late Animation<double> _bookZoom;

  // Phase 3: Cover opens slowly like a real book
  late AnimationController _coverOpenController;
  late Animation<double> _coverOpen;

  // Phase 4: Zoom into page (transition to app)
  late AnimationController _zoomInController;
  late Animation<double> _zoomIn;

  // Gold shimmer
  late AnimationController _shimmerController;

  // State
  int _lastReadPage = 1;
  int _phase = 0;
  String _currentReading = ReadingService.hafs;
  String? _mushafDirPath;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Phase 1: Logo (1.2s)
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));

    // Phase 2: Book zooms into view (1.5s)
    _bookZoomController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _bookZoom = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _bookZoomController, curve: Curves.easeOutCubic));

    // Phase 3: Cover opens slowly (2.5s — slower = more realistic)
    _coverOpenController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _coverOpen = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _coverOpenController, curve: Curves.easeInOutQuart));

    // Phase 4: Zoom into page (1s)
    _zoomInController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _zoomIn = Tween<double>(begin: 1.0, end: 3.0).animate(
        CurvedAnimation(parent: _zoomInController, curve: Curves.easeInCubic));

    // Shimmer loop
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _prefetchHomeData(); // 🏠 Start background loading immediately
    _startSequence();
  }

  /// 🏠 Pre-fetch heavy dashboard data while book is opening
  void _prefetchHomeData() {
    Future.wait([
      DailyVerseService.getTodayVerse(),
      StreakService.getStreakData(),
      ReadingStatsService.getStats(),
      Provider.of<AchievementService>(context, listen: false).init(),
    ]).catchError((e) {
      debugPrint('🏠 Dashboard Pre-fetch Error: $e');
      return <void>[]; 
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 🚀 تحسين التحميل المسبق للصور (Precache)
    Future.wait([
      precacheImage(const AssetImage('assets/images/logo.png'), context),
      precacheImage(const AssetImage('assets/images/quran_logo_premium.png'), context),
    ]);
  }

  Future<void> _startSequence() async {
    // 🚀 تشغيل العمليات الثقيلة بالتوازي
    // Run heavy I/O operations in parallel
    final results = await Future.wait([
      BookmarkService.getLastRead(),
      ReadingService.getSelectedReading(),
      getApplicationDocumentsDirectory(),
    ]);

    final lastRead = results[0] as Map<String, dynamic>?;
    _lastReadPage = lastRead?['pageNumber'] ?? 1;
    _currentReading = results[1] as String;
    
    final dir = results[2] as Directory;
    final folderName = _currentReading == ReadingService.hafs
        ? 'mushaf_hafs'
        : 'mushaf_warsh';
    
    final path = Directory('${dir.path}/$folderName');
    if (await path.exists()) {
      _mushafDirPath = path.path;
    } else {
      final oldPath = Directory('${dir.path}/mushaf_pages');
      if (await oldPath.exists()) _mushafDirPath = oldPath.path;
    }

    if (!mounted) return;

    // === Phase 1: Logo ===
    _logoController.forward();
    
    // 📡 Check Firebase Auth while logo is showing
    if (mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      // We don't necessarily WAIT for it to finish because it's silent,
      // but we ensure it was at least triggered.
      if (authService.isFirebaseReady && !authService.isAuthenticated) {
        debugPrint('📡 Triggering silent auth during splash...');
      }
    }
    
    // Start pre-caching the first page image while logo is shown
    final pageStr = _lastReadPage.toString().padLeft(3, '0');
    final firstPageImage = AssetImage('assets/mushaf/page$pageStr.png');
    final precacheFuture = precacheImage(firstPageImage, context).catchError((_) {});

    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // === Phase 2: Book appears ===
    setState(() => _phase = 1);
    _bookZoomController.forward();
    
    // Wait for the book to zoom in AND for the first page to be ready
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      precacheFuture,
    ]);
    
    if (!mounted) return;

    // === Phase 3: Cover opens slowly ===
    setState(() => _phase = 2);
    _coverOpenController.forward();
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // === Phase 4: Zoom into page & navigate ===
    setState(() => _phase = 3);
    _zoomInController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Check for first launch
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

      if (isFirstLaunch) {
        // Mark as launched
        await prefs.setBool('isFirstLaunch', false);
        
        // Push Home screen to the stack, then push Mushaf on top of it!
        // This makes sure when they press "back", they go to the Home Screen.
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
        );
        
        // Push Mushaf (Surah Al-Fatihah, Page 1) immediately on top with no animation
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MushafViewerScreen(initialPage: 1),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        });
      } else {
        // 🚀 FAST STARTUP: Normal Launch -> DIRECT TO MUSHAF
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MushafViewerScreen(
              initialPage: _lastReadPage,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bookZoomController.dispose();
    _coverOpenController.dispose();
    _zoomInController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kDeepGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ornamental background
          const RepaintBoundary(child: _PremiumBackground()),

          // Main content
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _logoController,
                _bookZoomController,
                _coverOpenController,
                _zoomInController,
              ]),
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Logo Phase (fades out as book appears)
                    if (_phase <= 1)
                      Opacity(
                        opacity: _phase == 0
                            ? _logoFade.value
                            : (1.0 - _bookZoom.value * 2).clamp(0.0, 1.0),
                        child: _buildLogoPhase(),
                      ),

                    // Book Phase
                    if (_phase >= 1)
                      Transform.scale(
                        scale: _phase < 3
                            ? (_bookZoom.value * 0.4 + 0.6) // 0.6 → 1.0
                            : _zoomIn.value, // 1.0 → 3.0
                        child: Opacity(
                          opacity: _phase < 3
                              ? _bookZoom.value
                              : (1.0 - (_zoomIn.value - 1.0)).clamp(0.0, 1.0),
                          child: _buildBook(size),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Bottom branding
          _buildBottomBranding(),

          // Gold particles during book open
          if (_phase >= 2 && _phase < 3)
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) =>
                  CustomPaint(painter: _GoldParticlesPainter(
                    progress: _shimmerController.value,
                    screenSize: size,
                  )),
            ),
        ],
      ),
    );
  }

  // ============================================================
  //  LOGO PHASE
  // ============================================================
  Widget _buildLogoPhase() {
    return ScaleTransition(
      scale: _logoScale,
      child: FadeTransition(
        opacity: _logoFade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo with golden glow
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kRichGold.withValues(alpha: 0.2),
                    blurRadius: 60,
                    spreadRadius: 15,
                  ),
                  BoxShadow(
                    color: _kDeepGreen.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Image(
                  image: AssetImage('assets/images/logo.png'), width: 160),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  BOTTOM BRANDING
  // ============================================================
  Widget _buildBottomBranding() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _phase <= 1 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          children: [
            Text(
              'تلا القرآن',
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _kRichGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'TALA QURAN',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.textMuted,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  3D BOOK — المصحف ثلاثي الأبعاد
  // ============================================================
  Widget _buildBook(Size screenSize) {
    final bookWidth = screenSize.width * 0.88;
    final bookHeight = bookWidth * 1.42;
    
    // 🚀 Overhang Squares: Making the cover slightly larger than the page block
    // Increased to 8.0 for absolute coverage against perspective gaps.
    const double overhang = 8.0;
    final coverWidth = bookWidth;
    final coverHeight = bookHeight + overhang;
    
    final coverProgress = _coverOpen.value;

    return SizedBox(
      width: bookWidth + 16, // extra for spine
      height: coverHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // === 1. Back cover (always visible below) ===
          Positioned(
            left: 16,
            child: _PremiumBookCover(
              width: coverWidth,
              height: coverHeight,
              isBack: true,
            ),
          ),

          // === 2. Page stack below the opening cover ===
          // Centered vertically relative to the larger cover
          Positioned(
            left: 16,
            child: _PageStack(
              width: bookWidth - 4, // Slightly inset at the sides
              height: bookHeight,     // Original page height
              visible: coverProgress > 0.3,
              opacity: ((coverProgress - 0.3) / 0.3).clamp(0.0, 1.0),
              pageNumber: _lastReadPage,
              reading: _currentReading,
              dirPath: _mushafDirPath,
            ),
          ),

          // === 3. Book edge (page thickness) ===
          // Rendered BEFORE front cover so it's hidden when closed
          if (coverProgress < 0.5)
            Positioned(
              bottom: overhang / 2, // Centered relative to overhang
              left: 16,
              right: 0,
              child: _BookEdge(
                width: bookWidth - 4, // Match inset page stack
                visible: coverProgress < 0.4,
              ),
            ),

          // === 4. Front cover (opens with 3D rotation) ===
          Positioned(
            left: 16,
            child: Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0008) // Stronger perspective
                ..rotateY(-(coverProgress * pi * 0.9)),
              child: Opacity(
                opacity: (1.0 - coverProgress * 1.3).clamp(0.0, 1.0),
                child: _PremiumBookCover(
                  width: coverWidth,
                  height: coverHeight,
                  isBack: false,
                  coverProgress: coverProgress,
                ),
              ),
            ),
          ),

          // === 5. Spine (Moved to the right for RTL flow) ===
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _BookSpine(
              width: 18,
              height: coverHeight,
              openProgress: coverProgress,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  PREMIUM BOOK COVER — غلاف المصحف الاحترافي
// ============================================================
class _PremiumBookCover extends StatelessWidget {
  final double width;
  final double height;
  final bool isBack;
  final double coverProgress;

  const _PremiumBookCover({
    required this.width,
    required this.height,
    this.isBack = false,
    this.coverProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kCoverGreen,
            _kCoverDark,
            _kCoverGreen.withValues(alpha: 0.95),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: _kRichGold.withValues(alpha: 0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isBack ? 0.5 : 0.4),
            blurRadius: isBack ? 20 : 15,
            offset: Offset(isBack ? 0 : 5, isBack ? 3 : 5),
          ),
          if (!isBack)
            BoxShadow(
              color: _kRichGold.withValues(alpha: 0.08),
              blurRadius: 25,
              spreadRadius: -3,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Leather texture effect
            CustomPaint(
              painter: _LeatherTexturePainter(isBack: isBack),
            ),

            if (!isBack) ...[
              // Ornamental frame
              CustomPaint(
                painter: _OrnamentalCoverPainter(),
              ),

              // Center medallion
              Opacity(
                opacity: (1.0 - coverProgress * 3.0).clamp(0.0, 1.0),
                child: _buildCenterContent(),
              ),

              // Corner ornaments
              ..._buildCornerOrnaments(),
            ],

            // Inner border frame
            Container(
              margin: EdgeInsets.all(isBack ? 12 : 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _kRichGold.withValues(alpha: isBack ? 0.2 : 0.35),
                  width: isBack ? 1 : 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Double inner border
            if (!isBack)
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _kRichGold.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top ornamental line
          const _GoldDivider(width: 120),
          const SizedBox(height: 10),

          // Central medallion container
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _kRichGold.withValues(alpha: 0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kRichGold.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _kRichGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/quran_logo_premium.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Title below medallion
          Text(
            'القرآن الكريم',
            style: GoogleFonts.amiri(
              color: _kRichGold,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: _kRichGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تلا القرآن',
            style: GoogleFonts.amiri(
              color: _kLightGold.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),
          const _GoldDivider(width: 120),
        ],
      ),
    );
  }

  List<Widget> _buildCornerOrnaments() {
    return [
      // Top-left
      const Positioned(
        top: 20, left: 20,
        child: _CornerOrnament(rotation: 0),
      ),
      // Top-right
      const Positioned(
        top: 20, right: 20,
        child: _CornerOrnament(rotation: pi / 2),
      ),
      // Bottom-left
      const Positioned(
        bottom: 20, left: 20,
        child: _CornerOrnament(rotation: -pi / 2),
      ),
      // Bottom-right
      const Positioned(
        bottom: 20, right: 20,
        child: _CornerOrnament(rotation: pi),
      ),
    ];
  }
}

// ============================================================
//  CORNER ORNAMENT
// ============================================================
class _CornerOrnament extends StatelessWidget {
  final double rotation;
  const _CornerOrnament({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: const Size(30, 30),
        painter: _CornerOrnamentPainter(),
      ),
    );
  }
}

class _CornerOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // L-shape with curves
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.3)
      ..quadraticBezierTo(0, 0, size.width * 0.3, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);

    // Inner arc
    final innerPaint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width * 0.6, size.height * 0.6),
      pi / 2, -pi / 2, false, innerPaint,
    );

    // Dot
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      2,
      Paint()..color = _kRichGold.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ============================================================
//  GOLD DIVIDER
// ============================================================
class _GoldDivider extends StatelessWidget {
  final double width;
  const _GoldDivider({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 12,
      child: CustomPaint(painter: _GoldDividerPainter()),
    );
  }
}

class _GoldDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    final y = size.height / 2;
    // Lines
    canvas.drawLine(Offset(0, y), Offset(size.width * 0.35, y), paint);
    canvas.drawLine(
        Offset(size.width * 0.65, y), Offset(size.width, y), paint);
    // Center diamond
    final cx = size.width / 2;
    final path = Path()
      ..moveTo(cx, y - 4)
      ..lineTo(cx + 6, y)
      ..lineTo(cx, y + 4)
      ..lineTo(cx - 6, y)
      ..close();
    canvas.drawPath(
        path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ============================================================
//  BOOK SPINE — كعب المصحف
// ============================================================
class _BookSpine extends StatelessWidget {
  final double width;
  final double height;
  final double openProgress;

  const _BookSpine({
    required this.width,
    required this.height,
    required this.openProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3516), // Dark Green Spine
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(2, 0), // Shadow towards the pages
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF1B2E13),
            Color(0xFF2D4F1E),
            Color(0xFF1B2E13),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical Gold Line
          Container(
            width: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _kRichGold.withValues(alpha: 0.8),
                  _kRichGold.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Small decorative dots
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) => Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _kRichGold,
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  BOOK EDGE — حافة الكتاب (سمك الصفحات)
// ============================================================
class _BookEdge extends StatelessWidget {
  final double width;
  final bool visible;

  const _BookEdge({
    required this.width,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kParchmentDark,
            _kParchment.withValues(alpha: 0.9),
            _kParchmentDark,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: _kDarkGold.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  PAGE STACK — كومة الصفحات تحت الغلاف
// ============================================================
class _PageStack extends StatelessWidget {
  final double width;
  final double height;
  final bool visible;
  final double opacity;
  final int pageNumber;
  final String reading;
  final String? dirPath;

  const _PageStack({
    required this.width,
    required this.height,
    required this.visible,
    required this.opacity,
    this.pageNumber = 1,
    this.reading = ReadingService.hafs,
    this.dirPath,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _kParchment,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _kDarkGold.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 📜 1. Base parchment texture
              CustomPaint(painter: _PaperTexturePainter()),

              // 📖 2. Actual page content (Actual image from Quran)
              Padding(
                padding: const EdgeInsets.all(12.0), // Space for the ornament
                child: _buildPageContent(),
              ),

              // 🎨 3. Premium Islamic Ornamental Frame
              CustomPaint(painter: _IslamicPageBorderPainter()),

              // 🌗 4. Binding Shadow (Realistic crease in the middle)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                    ],
                    stops: const [0.0, 0.05, 1.0],
                  ),
                ),
              ),

              // 🕌 5. Inner decorative frame (thin gold)
              Container(
                margin: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _kRichGold.withValues(alpha: 0.2),
                    width: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    final pageStr = pageNumber.toString().padLeft(3, '0');
    return Image.asset(
      'assets/mushaf/page$pageStr.png',
      fit: BoxFit.fill,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: _kParchment,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                  style: GoogleFonts.amiri(
                    color: _kCoverDark.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                for (int i = 0; i < 10; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Container(
                      height: 1.5,
                      margin: EdgeInsets.symmetric(horizontal: 30.0 + i * 2),
                      color: _kCoverDark.withValues(alpha: 0.05),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
//  PAINTERS
// ============================================================

/// خلفية مزخرفة بدوائر وبنمط هندسي إسلامي
class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PremiumBackgroundPainter());
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0A3326),
          Color(0xFF062218),
          Color(0xFF041A12),
          Color(0xFF031510),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle ornamental circles
    final ornamentPaint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 1; i <= 10; i++) {
      canvas.drawCircle(Offset(cx, cy), i * 60.0, ornamentPaint);
    }

    // Cross pattern
    final linePaint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.015)
      ..strokeWidth = 0.3;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// تأثير نسيج الجلد على الغلاف
class _LeatherTexturePainter extends CustomPainter {
  final bool isBack;
  _LeatherTexturePainter({this.isBack = false});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for consistency
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// إطار زخرفي إسلامي على الغلاف
class _OrnamentalCoverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer frame
    final outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(22, 22, size.width - 44, size.height - 44),
      const Radius.circular(4),
    );
    canvas.drawRRect(outerRect, paint);

    // Middle frame
    final midPaint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final midRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(28, 28, size.width - 56, size.height - 56),
      const Radius.circular(3),
    );
    canvas.drawRRect(midRect, midPaint);

    // Top & bottom decorative lines
    final linePaint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.2)
      ..strokeWidth = 0.8;

    // Top
    canvas.drawLine(
      Offset(size.width * 0.25, 35),
      Offset(size.width * 0.75, 35),
      linePaint,
    );
    // Bottom
    canvas.drawLine(
      Offset(size.width * 0.25, size.height - 35),
      Offset(size.width * 0.75, size.height - 35),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// ذرات ذهبية متناثرة أثناء فتح الغلاف
class _GoldParticlesPainter extends CustomPainter {
  final double progress;
  final Size screenSize;

  _GoldParticlesPainter({required this.progress, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(77);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 25; i++) {
      final baseX = screenSize.width * 0.3 + random.nextDouble() * screenSize.width * 0.4;
      final baseY = screenSize.height * 0.2 + random.nextDouble() * screenSize.height * 0.6;
      final offsetY = sin((progress + i * 0.1) * pi * 2) * 20;
      final offsetX = cos((progress + i * 0.15) * pi * 2) * 10;
      final alpha = (sin((progress + i * 0.2) * pi * 2) * 0.5 + 0.5) * 0.3;
      final radius = 1.0 + random.nextDouble() * 1.5;

      paint.color = _kRichGold.withValues(alpha: alpha.clamp(0.0, 0.3));
      canvas.drawCircle(
        Offset(baseX + offsetX, baseY + offsetY),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldParticlesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// زخرفة الميدالية المركزية - Islamic Medallion Ornament

// ============================================================
//  NEW PAINTERS FOR PAGE ENHANCEMENT
// ============================================================

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(123);
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Tiny fiber dots
    for (int i = 0; i < 400; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.03;
      paint.color = const Color(0xFF8B4513).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.0, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _IslamicPageBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kRichGold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const margin = 10.0;
    final rect = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);

    // 1. Double border frame
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect.deflate(2), paint..strokeWidth = 0.5);

    // 2. Corner Arabesque Nodes
    const nodeSize = 15.0;
    _drawCornerNode(canvas, const Offset(margin, margin), 0, nodeSize, paint);
    _drawCornerNode(canvas, Offset(size.width - margin, margin), pi / 2, nodeSize, paint);
    _drawCornerNode(canvas, Offset(margin, size.height - margin), -pi / 2, nodeSize, paint);
    _drawCornerNode(canvas, Offset(size.width - margin, size.height - margin), pi, nodeSize, paint);
    
    // 3. Side decorative links
    _drawSideOrnament(canvas, size, paint);
  }

  void _drawCornerNode(Canvas canvas, Offset center, double rotation, double size, Paint paint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(size * 0.5, -size * 0.2, size, 0)
      ..quadraticBezierTo(size * 1.2, size * 0.5, size, size)
      ..quadraticBezierTo(-size * 0.2, size * 0.5, 0, 0);
    
    canvas.drawPath(path, paint..style = PaintingStyle.fill..color = _kRichGold.withValues(alpha: 0.15));
    canvas.drawPath(path, paint..style = PaintingStyle.stroke..color = _kRichGold.withValues(alpha: 0.4)..strokeWidth = 0.8);
    
    canvas.restore();
  }

  void _drawSideOrnament(Canvas canvas, Size size, Paint paint) {
    const margin = 10.0;

    // Decoration on left and right sides
    for (double y in [size.height * 0.3, size.height * 0.7]) {
      canvas.drawCircle(Offset(margin, y), 2.5, paint..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(size.width - margin, y), 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
