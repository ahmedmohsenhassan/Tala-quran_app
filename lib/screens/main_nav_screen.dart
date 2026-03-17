import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'bookmarks_screen.dart';
import 'recitations_screen.dart';
import 'mushaf_viewer_screen.dart';
import 'stats_screen.dart';
import 'juz_hizb_screen.dart';

class MainNavScreen extends StatefulWidget {
  final int initialPage;
  const MainNavScreen({super.key, this.initialPage = 1});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MushafViewerScreen(initialPage: widget.initialPage),
      const HomeScreen(),
      const JuzHizbScreen(),
      const RecitationsScreen(),
      const StatsScreen(),
      const BookmarksScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBody: true, // This allows the body to go behind the bottom bar
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildFloatingDock(),
      ),
    );
  }

  Widget _buildFloatingDock() {
    return Container(
      height: 90,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.menu_book_rounded, 'المصحف'),
                _buildNavItem(1, Icons.grid_view_rounded, 'الفهرس'),
                _buildNavItem(2, Icons.library_books_rounded, 'الأجزاء'),
                _buildNavItem(3, Icons.mic_none_rounded, 'التلاوات'),
                _buildNavItem(4, Icons.bar_chart_rounded, 'الإحصائيات الذكية'),
                _buildNavItem(5, Icons.bookmark_outline_rounded, 'المحفوظات'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.amiri(
              color: isSelected ? AppColors.gold : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
