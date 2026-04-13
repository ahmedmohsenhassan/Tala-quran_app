import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:showcaseview/showcaseview.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'juz_list_screen.dart';
import 'settings_tab.dart';
import '../widgets/spiritual_background.dart';

import 'constellation_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final int? autoOpenPage;
  const MainDashboardScreen({super.key, this.autoOpenPage});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Placeholder screens until JuzList and Settings tabs are fully implemented
  final List<Widget> _pages = [
    const HomeScreen(),
    const JuzListScreen(),
    const ConstellationScreen(),
    const SearchScreen(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      // ignore: deprecated_member_use
      child: ShowCaseWidget(
        builder: (context) => Scaffold(
        body: Stack(
          children: [
            const SpiritualBackground(),
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                return PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    if (index != _currentIndex) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    double value;
                    if (_pageController.position.hasContentDimensions) {
                      value = (_pageController.page ?? _currentIndex.toDouble()) - index;
                    } else {
                      value = (_currentIndex.toDouble()) - index;
                    }
                    
                    // حساب زاوية الدوران ثلاثي الأبعاد للتبويبات
                    double angle = (value * -3.14 / 8).clamp(-3.14 / 8, 3.14 / 8);
                    
                    return Transform(
                      alignment: value > 0 ? Alignment.centerRight : Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: Opacity(
                        opacity: (1 - value.abs()).clamp(0.0, 1.0),
                        child: _pages[index],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        extendBody: true, // Allows body to scroll behind the floating nav bar
        bottomNavigationBar: _buildPremiumBottomNavBar(),
      ),
      ),
    );
  }

  Widget _buildPremiumBottomNavBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 🚀 تقليل قوة التغبيش لزيادة السرعة
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              selectedItemColor: AppColors.gold,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.amiri(fontSize: 11),
              onTap: (index) {
                if (index != _currentIndex) {
                  HapticFeedback.selectionClick();
                }
                setState(() {
                  _currentIndex = index;
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOutCubic,
                  );
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined),
                  activeIcon: Icon(Icons.menu_book_rounded),
                  label: 'الأجزاء',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.stars_outlined),
                  activeIcon: Icon(Icons.stars_rounded),
                  label: 'النجوم',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search_rounded),
                  label: 'بحث',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'إعدادات',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
