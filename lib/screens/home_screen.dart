import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Utils & Colors
import '../utils/app_colors.dart';

// Services
import '../services/daily_verse_service.dart';
import '../services/reading_stats_service.dart';
import '../services/streak_service.dart';
import '../services/bookmark_service.dart';

// Widgets - Home Components
import '../widgets/home/home_header.dart';
import '../widgets/home/daily_verse_card.dart';
import '../widgets/home/khatma_progress_card.dart';
import '../widgets/home/achievement_gallery.dart';
import '../widgets/home/community_impact_card.dart';
import '../widgets/home/quick_access_dashboard.dart';
import '../widgets/home/surah_tab_content.dart';
import '../widgets/home/juz_tab_content.dart';
import '../widgets/home/favorites_tab_content.dart';

// Screens
import 'search_screen.dart';

/// 🏠 الشاشة الرئيسية لتطبيق تلا القرآن (النسخة المنظمة)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _dailyVerse;
  Map<String, dynamic>? _statsData;
  Map<String, dynamic>? _streakData;
  Map<String, dynamic>? _lastRead;
  bool _isLoading = true;

  // Showcase Keys
  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _quickAccessKey = GlobalKey();
  final GlobalKey _continueReadingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final dailyVerse = await DailyVerseService.getTodayVerse();
    final stats = await ReadingStatsService.getStats();
    final streak = await StreakService.getStreakData();
    final lastRead = await BookmarkService.getLastRead();

    if (mounted) {
      setState(() {
        _dailyVerse = dailyVerse;
        _statsData = stats;
        _streakData = streak;
        _lastRead = lastRead;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const HomeHeader(),
                      const SizedBox(height: 24),
                      if (_dailyVerse != null) ...[
                        DailyVerseCard(verse: _dailyVerse!),
                        const SizedBox(height: 24),
                      ],
                      _buildKhatmaProgress(),
                      const SizedBox(height: 24),
                      QuickAccessDashboard(
                        statsData: _statsData,
                        streakData: _streakData,
                        lastRead: _lastRead,
                        onRefresh: _loadData,
                        statsKey: _quickAccessKey,
                        continueReadingKey: _continueReadingKey,
                      ),
                      const SizedBox(height: 24),
                      const AchievementGallery(),
                      const SizedBox(height: 24),
                      const CommunityImpactCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildSliverTabBar(),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              SurahTabContent(onRefresh: _loadData),
              const JuzTabContent(),
              const FavoritesTabContent(),
            ],
          ),
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildKhatmaProgress() {
    if (_lastRead == null) return const SizedBox();
    
    final currentPage = _lastRead!['pageNumber'] as int? ?? 1;
    const totalPages = 604;
    final progress = (currentPage / totalPages).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(1);

    return KhatmaProgressCard(
      currentPage: currentPage,
      totalPages: totalPages,
      progress: progress,
      percent: percent,
      showcaseKey: _progressKey,
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
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
    );
  }
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
