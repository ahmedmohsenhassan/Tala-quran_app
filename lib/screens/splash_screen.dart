import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tala_quran_app/screens/main_nav_screen.dart';
import '../utils/app_colors.dart';
import '../services/bookmark_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // جلب آخر صفحة تم قرأتها - Fetch last read page
    final lastRead = await BookmarkService.getLastRead();
    final int initialPage = lastRead?['pageNumber'] ?? 1;

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavScreen(initialPage: initialPage),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage('assets/images/logo.png'),
                width: 140,
              ),
              const SizedBox(height: 24),
              Text(
                'تلا قرآن',
                style: GoogleFonts.amiri(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tala Quran',
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
