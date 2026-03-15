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
import 'surah_detail_screen.dart';
import 'search_screen.dart';
import '../services/kids_mode_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _lastRead;
  Map<String, dynamic>? _streakData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final lastRead = await BookmarkService.getLastRead();
    final streak = await StreakService.getStreakData();
    if (mounted) {
      setState(() {
        _lastRead = lastRead ??
            {
              'surahNumber': 1,
              'surahName': 'الفاتحة',
              'pageNumber': 1,
              'isDefault': true,
            };
        _streakData = streak;
      });
      // عرض رسالة ترحيبية ذكية — Show smart welcome message
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
            // خلفية متحركة بريميوم — Premium Animated Background
            const _AnimatedBackground(),

            // المحتوى الرئيسي
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
                          const SizedBox(height: 32),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
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
              onTap: () => _showReadModeDialog(context, surah),
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
    return const Center(
        child: Text('قريباً...', style: TextStyle(color: Colors.white)));
  }

  Widget _buildFavoritesTab() {
    return const Center(
        child: Text('لا توجد مفضلات بعد', style: TextStyle(color: Colors.white)));
  }

  Widget _buildQuickAccessDashboard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
          children: [
            _buildKhatmaCard(),
            const SizedBox(width: 16),
            if (_streakData != null) ...[
              _buildStreakCard(),
              const SizedBox(width: 16),
            ],
            if (_lastRead != null) _buildLastReadCard(),
          ],
      ),
    );
  }

  Widget _buildKhatmaCard() {
    return Container(
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
              Text('ختم القرآن',
                  style: GoogleFonts.amiri(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text('ابدأ خطة قراءة جديدة',
              style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLastReadCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MushafViewerScreen(initialPage: _lastRead!['pageNumber']),
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
                const Icon(Icons.bookmark_rounded,
                    color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(_lastRead!['surahName'] ?? 'الكهف',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: AppColors.gold, size: 16),
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

  String _getDayGreetingAr() {
    final day = DateTime.now().weekday;
    switch (day) {
      case DateTime.friday:
        return 'جمعة مباركة';
      case DateTime.saturday:
        return 'سبت مبارك';
      case DateTime.sunday:
        return 'أحد مبارك';
      case DateTime.monday:
        return 'اثنين مبارك';
      case DateTime.tuesday:
        return 'ثلاثاء مباركة';
      case DateTime.wednesday:
        return 'أربعاء مباركة';
      case DateTime.thursday:
        return 'خميس مبارك';
      default:
        return 'يوم مبارك';
    }
  }

  void _showReadModeDialog(BuildContext context, Map<String, dynamic> surah) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'سورة ${surah['name']}',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _ReadModeOption(
                icon: Icons.menu_book_rounded,
                title: 'قراءة من المصحف',
                subtitle: 'تجربة بصرية كلاسيكية',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MushafViewerScreen(
                        initialPage:
                            QuranPageHelper.getPageForSurah(surah['number']),
                      ),
                    ),
                  ).then((_) => _loadData());
                },
              ),
              const SizedBox(height: 12),
              _ReadModeOption(
                icon: Icons.text_snippet_rounded,
                title: 'قراءة نصية حديثة',
                subtitle: 'خطوط واضحة ونظام تصفح سريع',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(
                        surahNumber: surah['number'],
                        surahName: surah['name'],
                      ),
                    ),
                  ).then((_) => _loadData());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReadModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style:
                        GoogleFonts.amiri(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white24, size: 14),
          ],
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
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
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                0.5 * (1 + 0.3 * (0.5 - _controller.value).abs()),
                -0.5 + 0.2 * _controller.value,
              ),
              radius: 1.5,
              colors: [
                AppColors.emerald.withValues(alpha: 0.08),
                AppColors.background,
              ],
            ),
          ),
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ArabesquePatternPainter(color: AppColors.gold),
            ),
          ),
        );
      },
    );
  }
}

class _ArabesquePatternPainter extends CustomPainter {
  final Color color;
  _ArabesquePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawIslamicStar(canvas, Offset(x, y), 25, paint);
      }
    }
  }

  void _drawIslamicStar(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final Path path = Path();
    for (int i = 0; i < 9; i++) {
      double angle = (i * 45) * math.pi / 180;
      double r = i % 2 == 0 ? radius : radius * 0.5;
      double x = center.dx + r * math.cos(angle);
      double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, radius * 0.2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
