import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surah_metadata.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import 'mushaf_viewer_screen.dart';
import 'search_screen.dart';
import 'reading_plan_screen.dart';
import 'stats_screen.dart';
import 'smart_hifz_screen.dart';
import '../services/reading_stats_service.dart';
import '../services/kids_mode_service.dart';
import '../data/rub_data.dart';
import 'package:provider/provider.dart';
import '../widgets/premium_painters.dart';
import '../services/theme_service.dart';
import '../services/daily_verse_service.dart';
import '../widgets/ayah_share_card.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _lastRead;
  Map<String, dynamic>? _streakData;
  Map<String, dynamic>? _statsData;
  Map<String, dynamic>? _dailyVerse;
  late TabController _tabController;

  final GlobalKey _continueReadingKey = GlobalKey();
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _quickAccessKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    
    // Feature Discovery Tour
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final isHomeTourCompleted = prefs.getBool('isHomeTourCompleted') ?? false;
      
      if (!isHomeTourCompleted && mounted) {
        await prefs.setBool('isHomeTourCompleted', true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            // ignore: deprecated_member_use
            ShowCaseWidget.of(context).startShowCase([
              _continueReadingKey,
              _progressKey,
              _quickAccessKey,
            ]);
          }
        });
      }
    });
  }

  Future<void> _loadData() async {
    final lastRead = await BookmarkService.getLastRead();
    final streak = await StreakService.getStreakData();
    final stats = await ReadingStatsService.getStats();
    final dailyVerse = await DailyVerseService.getTodayVerse();
    
    if (mounted) {
      setState(() {
        _lastRead = lastRead ?? {
          'surahNumber': 1,
          'surahName': 'الفاتحة',
          'pageNumber': 1,
          'isDefault': true,
        };
        _streakData = streak;
        _statsData = stats;
        _dailyVerse = dailyVerse;
      });
      final settings = await NotificationService.getSettings();
      if (settings['enabled'] == true) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            NotificationService.showInAppNotification(context);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const _AnimatedBackground(),
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildWelcomeHeader(),
                          const SizedBox(height: 24),
                          if (_dailyVerse != null) ...[
                            _buildDailyVerseCard(),
                            const SizedBox(height: 24),
                          ],
                          if (_lastRead != null) ...[
                            _buildQuranProgressSection(),
                            const SizedBox(height: 24),
                          ],
                          _buildQuickAccessDashboard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      child: Container(
                        color: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.gold,
                          labelColor: AppColors.gold,
                          unselectedLabelColor: AppColors.textMuted,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.amiri(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          tabs: const [
                            Tab(text: 'السورة'),
                            Tab(text: 'الجزء'),
                            Tab(text: 'المفضلة'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahTab(),
                  _buildJuzTab(),
                  _buildFavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
        onPressed: () {},
      ),
      title: Text(
        'القرآن الكريم',
        style: GoogleFonts.amiri(
          color: AppColors.gold,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: AppColors.gold),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    final kidsMode = Provider.of<KidsModeService>(context);
    final isKids = kidsMode.isKidsModeActive;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardBackground,
                    AppColors.background.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.02),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: CustomPaint(
                  painter: _ArabesquePatternPainter(color: AppColors.gold),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Icon(Icons.mosque_rounded,
                  color: Colors.white.withValues(alpha: 0.05), size: 180),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.gold, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'السلام عليكم ورحمة الله',
                        style: GoogleFonts.amiri(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE8C76A)],
                    ).createShader(bounds),
                    child: Text(
                      isKids
                          ? 'هيا يا بطل، لنقرأ القرآن! 🌟'
                          : 'نور حياتك بالقرآن الكريم',
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: isKids ? 34 : 30,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.gold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _getDayGreetingAr(),
                          style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  DAILY VERSE CARD 🌟✨
  // ============================================================
  Widget _buildDailyVerseCard() {
    final verse = _dailyVerse!;
    final body = verse['body'] as String;
    final surah = verse['surah'] as int? ?? 0;
    final ayah = verse['ayah'] as int? ?? 0;

    return GestureDetector(
      onTap: surah > 0
          ? () {
              final page = QuranPageHelper.getPageForSurah(surah);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafViewerScreen(initialPage: page),
                ),
              );
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D2818),
              AppColors.emerald.withValues(alpha: 0.15),
              const Color(0xFF0A1F14),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'آية اليوم',
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (surah > 0)
                  GestureDetector(
                    onTap: () {
                      // Extract just the verse text (what's inside ﴿ ﴾)
                      final verseText = RegExp(r'﴿(.+?)﴾').firstMatch(body)?.group(1) ?? body;
                      // Extract surah name from body
                      final surahRef = RegExp(r'—\s*(.+)$').firstMatch(body)?.group(1) ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AyahShareCard(
                            ayahText: '﴿$verseText﴾',
                            surahName: surahRef.split(':').first.trim(),
                            ayahNumber: ayah,
                            surahNumber: surah,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.share_rounded, color: AppColors.gold.withValues(alpha: 0.7), size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Ornament
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoldLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.auto_awesome, color: AppColors.gold.withValues(alpha: 0.4), size: 14),
                ),
                _buildGoldLine(),
              ],
            ),
            const SizedBox(height: 16),

            // Verse text
            Text(
              body,
              style: GoogleFonts.amiri(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
                height: 1.9,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Bottom ornament
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGoldLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.auto_awesome, color: AppColors.gold.withValues(alpha: 0.4), size: 14),
                ),
                _buildGoldLine(),
              ],
            ),

            if (surah > 0) ...[
              const SizedBox(height: 12),
              Text(
                'اضغط للقراءة في المصحف →',
                style: GoogleFonts.amiri(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoldLine() {
    return Container(
      width: 50,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.0),
            AppColors.gold.withValues(alpha: 0.4),
            AppColors.gold.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  QURAN COMPLETION PROGRESS 📊🎯✨
  // ============================================================
  Widget _buildQuranProgressSection() {
    final currentPage = _lastRead!['pageNumber'] as int? ?? 1;
    const totalPages = 604;
    final progress = (currentPage / totalPages).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    // Milestone data
    final milestones = [
      {'page': 151, 'label': '¼', 'achieved': currentPage >= 151},
      {'page': 302, 'label': '½', 'achieved': currentPage >= 302},
      {'page': 453, 'label': '¾', 'achieved': currentPage >= 453},
      {'page': 604, 'label': 'ختم', 'achieved': currentPage >= 604},
    ];

    return Showcase(
      key: _progressKey,
      title: 'تقدمك في الختمة 📊',
      description: 'تابع شريط الإنجاز وتتبع كم صفحة أنهيت من كتاب الله.',
      tooltipBackgroundColor: AppColors.cardBackground,
      textColor: Colors.white,
      child: Container(
        width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'تقدمك في القرآن',
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: GoogleFonts.outfit(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          Stack(
            children: [
              // Track
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.gold : AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Milestone markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: milestones.map((m) {
              final achieved = m['achieved'] as bool;
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: achieved
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: achieved
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: achieved
                          ? const Icon(Icons.check_rounded, color: AppColors.gold, size: 14)
                          : Text(
                              m['label'] as String,
                              style: GoogleFonts.outfit(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ص${m['page']}',
                    style: GoogleFonts.outfit(
                      color: achieved ? AppColors.gold.withValues(alpha: 0.7) : AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

          const SizedBox(height: 8),
          Text(
            'صفحة $currentPage من $totalPages',
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildQuickAccessDashboard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _PremiumCardFrame(child: _buildJuzProgressCard()),
          const SizedBox(width: 16),
          _PremiumCardFrame(child: _buildSmartHifzCard()),
          const SizedBox(width: 16),
          _PremiumCardFrame(child: _buildKhatmaCard()),
          const SizedBox(width: 16),
          if (_statsData != null) ...[
            _PremiumCardFrame(child: _buildSmartStatsCard()),
            const SizedBox(width: 16),
          ],
          if (_streakData != null) ...[
            _PremiumCardFrame(child: _buildStreakCard()),
            const SizedBox(width: 16),
          ],
          if (_lastRead != null) _PremiumCardFrame(child: _buildLastReadCard()),
        ],
      ),
    );
  }

  // ============================================================
  //  JUZ PROGRESS RING 🏅✨
  // ============================================================
  Widget _buildJuzProgressCard() {
    if (_lastRead == null) return const SizedBox();

    final currentPage = _lastRead!['pageNumber'] as int? ?? 1;
    final currentJuz = QuranPageHelper.getJuzForPage(currentPage);
    final juzStart = QuranPageHelper.getPageForJuz(currentJuz);
    final juzEnd = QuranPageHelper.getJuzEndPage(currentJuz);
    final juzTotalPages = juzEnd - juzStart + 1;
    final pagesIntoJuz = currentPage - juzStart + 1;
    final progress = (pagesIntoJuz / juzTotalPages).clamp(0.0, 1.0);
    final percentText = '${(progress * 100).toInt()}%';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MushafViewerScreen(initialPage: currentPage),
        ),
      ).then((_) => _loadData()),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.emerald.withValues(alpha: 0.2),
              const Color(0xFF0D2818),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '🏅 الجزء $currentJuz',
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: _JuzProgressPainter(
                  progress: progress,
                  trackColor: AppColors.gold.withValues(alpha: 0.1),
                  progressColor: AppColors.gold,
                ),
                child: Center(
                  child: Text(
                    percentText,
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$pagesIntoJuz / $juzTotalPages صفحة',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            if (progress >= 1.0) ...[
              const SizedBox(height: 4),
              Text(
                '✨ مكتمل!',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartHifzCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartHifzScreen()),
      ).then((_) => _loadData()),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.gold, size: 24),
                const SizedBox(width: 8),
                Text('المساعد الذكي',
                    style: GoogleFonts.amiri(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('اختبر حفظك الآن',
                style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildKhatmaCard() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
      ).then((_) => _loadData()),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.emerald, size: 20),
                const SizedBox(width: 8),
                Text('خطط القراءة',
                    style: GoogleFonts.amiri(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('نظّم ختمتك وقراءتك',
                style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartStatsCard() {
    final stats = _statsData!;
    final double progress = stats['dailyGoalProgress'] ?? 0.0;
    final int todayPages = stats['todayPages'] ?? 0;

    return Showcase(
      key: _quickAccessKey,
      title: 'إحصائياتك الذكية ⚡',
      description: 'لوحة تحكمك الكاملة: خريطة حرارية وإحصائيات مفصلة لأدائك.',
      tooltipBackgroundColor: AppColors.cardBackground,
      textColor: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatsScreen()),
      ).then((_) => _loadData()),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_graph_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text('إحصائيات ذكية',
                    style: GoogleFonts.amiri(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$todayPages / 5 صفحة',
                    style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 11)),
                Text('${(progress * 100).toInt()}%',
                    style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildLastReadCard() {
    return Showcase(
      key: _continueReadingKey,
      title: 'إكمال القراءة 📖',
      description: 'بضغطة واحدة، عُد إلى نفس الصفحة التي توقفت عندها.',
      tooltipBackgroundColor: AppColors.cardBackground,
      textColor: Colors.white,
      child: InkWell(
        onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MushafViewerScreen(initialPage: _lastRead!['pageNumber']),
          ),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(_lastRead!['surahName'] ?? 'الفاتحة',
                    style: GoogleFonts.amiri(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('آخر تلاوة: صفحة ${_lastRead!['pageNumber']}',
                style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStreakCard() {
    final streak = _streakData!;
    final int currentStreak = streak['currentStreak'] ?? 0;
    final bool hasReadToday = streak['hasReadToday'] ?? false;
    final String emoji = streak['streakEmoji'] ?? '✨';

    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasReadToday
              ? AppColors.gold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('$currentStreak أيام',
                  style: GoogleFonts.amiri(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(hasReadToday ? 'قرأت اليوم ✓' : 'لم تقرأ بعد',
              style: GoogleFonts.amiri(
                  color: hasReadToday ? AppColors.emeraldLight : AppColors.textMuted,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSurahTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: surahMetadata.length,
      itemBuilder: (context, index) {
        final surah = surahMetadata[index];
        final bool showJuzHeader = _shouldShowJuzHeader(index);

        return Column(
          children: [
            if (showJuzHeader) _buildJuzHeader(surah['pageNumber']!),
            SurahCard(
              number: surah['number']!,
              name: surah['name']!,
              revelationType: surah['revelationType']!,
              totalAyahs: surah['totalAyahs']!,
              pageNumber: surah['pageNumber']!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MushafViewerScreen(
                      initialPage: surah['pageNumber']!,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowJuzHeader(int index) {
    if (index == 0) return true;
    final currentPage = surahMetadata[index]['pageNumber']!;
    final prevPage = surahMetadata[index - 1]['pageNumber']!;
    return QuranPageHelper.getJuzForPage(currentPage) !=
        QuranPageHelper.getJuzForPage(prevPage);
  }

  Widget _buildJuzHeader(int pageNumber) {
    final juz = QuranPageHelper.getJuzForPage(pageNumber);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Text(
            'جزء $juz',
            style: GoogleFonts.amiri(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: AppColors.gold.withValues(alpha: 0.1))),
          const SizedBox(width: 12),
          Text(
            '$pageNumber',
            style: GoogleFonts.outfit(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJuzTab() {
    const List<QuranQuarter> quarters = RubData.quarters;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: quarters.length,
      itemBuilder: (context, index) {
        final quarter = quarters[index];
        final bool showHeader = index == 0 || quarters[index-1].juz != quarter.juz;

        return Column(
          children: [
            if (showHeader) _buildSectionHeader('جزء ${quarter.juz}'),
            _buildRubCard(quarter),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.amiri(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: AppColors.gold.withValues(alpha: 0.1))),
        ],
      ),
    );
  }

  Widget _buildRubCard(QuranQuarter rub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MushafViewerScreen(initialPage: rub.page),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    rub.fractionText,
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontSize: rub.quarterInHizb == 4 ? 18 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rub.text.length > 45 ? '${rub.text.substring(0, 42)}...' : rub.text,
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          rub.surahName,
                          style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(
                          'آية ${rub.ayahNumber}',
                          style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${rub.page}',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return const Center(child: Text('لا توجد مفضلات بعد', style: TextStyle(color: Colors.white)));
  }

  String _getDayGreetingAr() {
    final day = DateTime.now().weekday;
    switch (day) {
      case DateTime.friday: return 'جمعة مباركة';
      case DateTime.saturday: return 'سبت مبارك';
      case DateTime.sunday: return 'أحد مبارك';
      case DateTime.monday: return 'اثنين مبارك';
      case DateTime.tuesday: return 'ثلاثاء مباركة';
      case DateTime.wednesday: return 'أربعاء مباركة';
      case DateTime.thursday: return 'خميس مبارك';
      default: return 'يوم مبارك';
    }
  }
}

class _PremiumCardFrame extends StatelessWidget {
  final Widget child;
  const _PremiumCardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CardFramePainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    PremiumPainters.drawFloralFrame(
      canvas: canvas,
      rect: Offset.zero & size,
      color: AppColors.gold.withValues(alpha: 0.4),
      edition: ThemeService.editionMadina1422,
      hasShadow: false,
    );
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverTabBarDelegate({required this.child});
  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ArabesquePatternPainter(
            color: AppColors.gold.withValues(alpha: 0.05),
            offset: _controller.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _ArabesquePatternPainter extends CustomPainter {
  final Color color;
  final double offset;
  _ArabesquePatternPainter({required this.color, this.offset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    for (double i = 0; i < size.width; i += 50) {
      for (double j = 0; j < size.height; j += 50) {
        final center = Offset(i, j);
        PremiumPainters.drawIslamicStar(canvas: canvas, center: center, radius: 15, color: color, filled: false);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// 🏅 Juz Progress Ring Painter
class _JuzProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _JuzProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -math.pi / 2; // Start from top
    const sweepTotal = 2 * math.pi * 0.75; // 270° sweep

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_JuzProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
