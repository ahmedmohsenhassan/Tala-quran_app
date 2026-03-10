import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tala_quran_app/screens/main_nav_screen.dart';
import '../utils/app_colors.dart';
import '../services/bookmark_service.dart';

/// شاشة البداية المتحركة — Animated Quran-Opening Splash
/// 3 Phases: Logo → Book Opening → Page Flip → Navigate
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase controllers
  late AnimationController _logoController;
  late AnimationController _bookController;
  late AnimationController _pageFlipController;

  // Logo animations
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Book opening animation (3D rotate)
  late Animation<double> _bookOpen;

  // Page flip animation
  late Animation<double> _pageFlip;

  // State
  int _phase = 0; // 0=logo, 1=book, 2=pages, 3=navigate
  int _lastReadPage = 1;

  @override
  void initState() {
    super.initState();

    // إخفاء أشرطة النظام — Hide system bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // --- Phase 1: Logo ---
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));

    // --- Phase 2: Book Opening ---
    _bookController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _bookOpen = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _bookController, curve: Curves.easeInOutQuart));

    // --- Phase 3: Page Flip ---
    _pageFlipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _pageFlip =
        CurvedAnimation(parent: _pageFlipController, curve: Curves.easeInOut);

    _startSequence();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache the logo to avoid JANK during first frame
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  Future<void> _startSequence() async {
    // تحميل أخر قراءة في الخلفية
    final lastRead = await BookmarkService.getLastRead();
    _lastReadPage = lastRead?['pageNumber'] ?? 1;

    // المرحلة الأولى: اللوجو
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;
    setState(() => _phase = 1);

    // المرحلة الثانية: فتح الكتاب
    _bookController.forward();
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;
    setState(() => _phase = 2);

    // المرحلة الثالثة: تقليب الصفحات
    _pageFlipController.forward();
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _phase = 3);

    // الانتقال للمنشور الرئيسي
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              MainNavScreen(initialPage: _lastReadPage),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bookController.dispose();
    _pageFlipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // عزل رسم الخلفية الثابتة لتحسين الأداء
          const RepaintBoundary(child: _BackgroundPattern()),

          // المحتوى الأساسي باستخدام Opacity للتحكم في الظهور لتجنب الـ Switcher Lag
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // اللوجو
                Opacity(
                  opacity: _phase == 0
                      ? 1.0
                      : (1.0 - _bookOpen.value).clamp(0.0, 1.0),
                  child: _buildLogoPhase(),
                ),

                // الكتاب (يتحرك في الاتجاه العربي - يفتح جهة اليمين)
                if (_phase >= 1)
                  Opacity(
                    opacity: _phase <= 2
                        ? 1.0
                        : (1.0 - _pageFlip.value).clamp(0.0, 1.0),
                    child: _buildBookPhase(size),
                  ),

                // التحميل النهائي
                if (_phase == 3)
                  FadeTransition(opacity: _pageFlip, child: _buildFinalPhase()),
              ],
            ),
          ),

          // العلامة التجارية في الأسفل
          _buildBottomBranding(),
        ],
      ),
    );
  }

  Widget _buildBottomBranding() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _phase == 0 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Column(
          children: [
            Text(
              'تلا قرآن',
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gold.withValues(alpha: 0.8),
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

  Widget _buildLogoPhase() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LogoImage(),
            const SizedBox(height: 40),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              style: GoogleFonts.amiri(
                fontSize: 28,
                color: AppColors.gold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookPhase(Size size) {
    final bookWidth = size.width * 0.85;
    final bookHeight = bookWidth * 1.4;
    final halfWidth = bookWidth / 2;

    return AnimatedBuilder(
      animation: Listenable.merge([_bookController, _pageFlipController]),
      builder: (context, child) {
        final progress = _bookOpen.value;
        final flipProgress = _pageFlip.value;

        return SizedBox(
          width: bookWidth,
          height: bookHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الصفحة اليمنى (ثابتة - تظهر كأول صفحة تحت الغلاف المفتوح)
              Positioned(
                right: 0,
                child: _BookPage(
                  width: halfWidth,
                  height: bookHeight,
                  isCoverSide: false,
                  showContent: progress > 0.8 || _phase >= 2,
                ),
              ),

              // الغلاف (يبدأ على اليمين ويفتح لليمين - اتجاه عربي)
              Positioned(
                right: 0,
                child: Transform(
                  alignment: Alignment.centerRight, // المفصلة على اليمين
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(-(progress * pi * 0.48)), // يفتح لليمين
                  child: _BookPage(
                    width: halfWidth,
                    height: bookHeight,
                    isCoverSide: true,
                    showContent: false,
                    coverProgress: progress,
                  ),
                ),
              ),

              // الصفحة اليسرى (تظهر بالتدريج عند فتح الكتاب)
              if (progress > 0.1)
                Positioned(
                  left: 0,
                  child: Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: _BookPage(
                      width: halfWidth,
                      height: bookHeight,
                      isCoverSide: false,
                      showContent: progress > 0.6 || _phase >= 2,
                    ),
                  ),
                ),

              // صفحات تتقلب
              if (_phase == 2)
                ..._buildFlippingPages(flipProgress, halfWidth, bookHeight),

              // مؤشر رقم الصفحة
              if (_phase >= 2)
                Positioned(
                  bottom: 30,
                  child: FadeTransition(
                    opacity: _pageFlip,
                    child: _PageLabel(lastRead: _lastReadPage),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFlippingPages(
      double progress, double width, double height) {
    const pageCount = 3;
    return List.generate(pageCount, (i) {
      final delay = i * 0.2;
      final pageProgress = ((progress - delay) / 0.8).clamp(0.0, 1.0);
      if (pageProgress <= 0 || pageProgress >= 1.0) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 0,
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(-(pageProgress * pi * 0.45)),
          child: _BookPage(
              width: width - 2,
              height: height - 10,
              isCoverSide: false,
              showContent: false),
        ),
      );
    });
  }

  Widget _buildFinalPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.gold),
        const SizedBox(height: 24),
        Text(
          'تلا قرآن',
          style: GoogleFonts.amiri(
              color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.15),
            blurRadius: 50,
            spreadRadius: 10,
          ),
        ],
      ),
      child:
          const Image(image: AssetImage('assets/images/logo.png'), width: 160),
    );
  }
}

class _BackgroundPattern extends StatelessWidget {
  const _BackgroundPattern();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BackgroundPainter());
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke;
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), i * 100.0, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _BookPage extends StatelessWidget {
  final double width;
  final double height;
  final bool isCoverSide;
  final bool showContent;
  final double coverProgress;

  const _BookPage({
    required this.width,
    required this.height,
    required this.isCoverSide,
    required this.showContent,
    this.coverProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isCoverSide ? AppColors.emerald : const Color(0xFFFFFDF0),
        borderRadius: BorderRadius.only(
          topLeft: isCoverSide ? const Radius.circular(8) : Radius.zero,
          bottomLeft: isCoverSide ? const Radius.circular(8) : Radius.zero,
          topRight: isCoverSide ? Radius.zero : const Radius.circular(8),
          bottomRight: isCoverSide ? Radius.zero : const Radius.circular(8),
        ),
        border:
            Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 3),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isCoverSide) _buildCoverOrnament(),
          if (showContent) const _PageLines(),
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.2), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverOrnament() {
    return Opacity(
      opacity: (1.0 - coverProgress * 2.5).clamp(0.0, 1.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.gold, size: 50),
          const SizedBox(height: 20),
          Text(
            'القرآن\nالكريم',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 32,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PageLines extends StatelessWidget {
  const _PageLines();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
            style: GoogleFonts.amiri(
                color: AppColors.emerald,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < 6; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                  height: 2,
                  width: double.infinity,
                  color: AppColors.emerald.withValues(alpha: 0.1)),
            ),
        ],
      ),
    );
  }
}

class _PageLabel extends StatelessWidget {
  final int lastRead;
  const _PageLabel({required this.lastRead});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)
        ],
      ),
      child: Text(
        'فتح صفحة $lastRead',
        style: GoogleFonts.amiri(
            color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
