import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'mushaf_viewer_screen.dart';
import 'recitations_screen.dart';
import 'juz_list_screen.dart';
import 'settings_tab.dart';

import '../services/notification_service.dart';
import '../widgets/notification_permission_dialog.dart';
import '../widgets/spiritual_background.dart';

/// 🏛️ مركز التنقل الرئيسي الموحد - Unified Navigation Center
/// يجمع بين الجمالية العالية والفعالية البرمجية
class MainDashboardScreen extends StatefulWidget {
  final int initialTabIndex;
  final int? initialMushafPage;

  const MainDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialMushafPage,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // 🔔 إدارة تصاريح الإشعارات عند الدخول
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final status = await NotificationService.getNotificationHealth();
      
      if (status['system_enabled'] == false || status['exact_alarm'] == false) {
        final prefs = await SharedPreferences.getInstance();
        final lastPrompt = prefs.getInt('last_notif_prompt') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // اطلب التصريح مرة كل 3 أيام إذا لم يتم منحه
        if (now - lastPrompt > 3 * 24 * 60 * 60 * 1000) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => NotificationPermissionDialog(
                isNotificationsEnabled: status['system_enabled'] ?? true,
                isExactAlarmEnabled: status['exact_alarm'] ?? true,
              ),
            );
            await prefs.setInt('last_notif_prompt', now);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // القائمة الموحدة للصفحات (4 تابات أساسية)
  List<Widget> get _pages => [
    const HomeScreen(),
    const RecitationsScreen(),
    const JuzListScreen(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
                      double value = 0;
                      if (_pageController.position.hasContentDimensions) {
                        value = (_pageController.page ?? _currentIndex.toDouble()) - index;
                      } else {
                        value = (_currentIndex.toDouble()) - index;
                      }
                      
                      // 3D Transition Angle (Adjusted for RTL)
                      double angle = (value * 3.14 / 12).clamp(-3.14 / 12, 3.14 / 12);
                      
                      return Transform(
                        alignment: value > 0 ? Alignment.centerLeft : Alignment.centerRight,
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
          extendBody: true,
          floatingActionButton: Container(
            margin: const EdgeInsets.only(top: 30), // لرفع الزر قليلاً عن الشريط العائم
            height: 64,
            width: 64,
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MushafViewerScreen(initialPage: widget.initialMushafPage ?? 1),
                  ),
                );
              },
              backgroundColor: AppColors.gold,
              elevation: 12,
              shape: const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold,
                      AppColors.gold.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 30),
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildPremiumBottomNavBar(),
        ),
      ),
    );
  }

  Widget _buildPremiumBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
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
                  setState(() {
                    _currentIndex = index;
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuart,
                    );
                  });
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'الرئيسية',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mic_none_outlined),
                  activeIcon: Icon(Icons.mic_none_rounded),
                  label: 'التلاوات',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'الفهرس',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'الإعدادات',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
