// Removed unused math import if needed, but I will keep it and fix the usage
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surahs.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import 'mushaf_viewer_screen.dart';
import 'surah_detail_screen.dart';
import '../services/kids_mode_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _lastRead;
  Map<String, dynamic>? _streakData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final lastRead = await BookmarkService.getLastRead();
    final streak = await StreakService.getStreakData();
    if (mounted) {
      setState(() {
        _lastRead = lastRead;
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // خلفية متحركة بريميوم — Premium Animated Background
            const _AnimatedBackground(),

            // المحتوى الرئيسي خلفية شفافة
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
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
                        if (_streakData != null) _buildStreakCard(),
                        const SizedBox(height: 24),
                        if (_lastRead != null) ...[
                          _buildQuickAccessSection(),
                          const SizedBox(height: 32),
                        ],
                        Text(
                          'الفهرس الشامل',
                          style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final surah = surahs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SurahCard(
                            number: surah['number'],
                            name: surah['name'],
                            englishName: surah['english_name'],
                            onTap: () => _showReadModeDialog(context, surah),
                          ),
                        );
                      },
                      childCount: surahs.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final kidsMode = Provider.of<KidsModeService>(context);
    final isKids = kidsMode.isKidsModeActive;

    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        isKids ? 'تلاوتي الجميلة 🌟' : 'تلا قرآن',
        style: GoogleFonts.amiri(
          color: isKids ? Colors.orange : AppColors.gold,
          fontSize: isKids ? 32 : 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: const [],
    );
  }

  Widget _buildWelcomeHeader() {
    final kidsMode = Provider.of<KidsModeService>(context);
    final isKids = kidsMode.isKidsModeActive;

    return Container(
      width: double.infinity,
      height: 190,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // خلفية متدرجة
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.emerald.withValues(alpha: 0.85),
                    AppColors.background.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // نمط أرابيسك زخرفي — Arabesque Pattern Overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.08,
                child: CustomPaint(
                  painter: _ArabesquePatternPainter(color: Colors.white),
                ),
              ),
            ),

            Positioned(
              left: -30,
              bottom: -30,
              child: Icon(Icons.mosque,
                  color: Colors.white.withValues(alpha: 0.06), size: 140),
            ),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.gold.withValues(alpha: 0.9), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'السلام عليكم',
                      style: GoogleFonts.amiri(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isKids ? 'هيا يا بطل، لنقرأ القرآن!' : 'نور حياتك بالقرآن',
                  style: GoogleFonts.amiri(
                    color: Colors.white,
                    fontSize: isKids ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                    ]
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.gold, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _getDayGreetingAr(),
                        style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ).paddingAll(24),
          ],
        ),
      ),
    );
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

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'متابعة الورد اليومي',
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.history_rounded,
                color: AppColors.gold.withValues(alpha: 0.5), size: 18),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            final int? page = _lastRead!['pageNumber'];
            final int surahNum = _lastRead!['surahNumber'] ?? 1;
            final targetPage = page ?? QuranPageHelper.getPageForSurah(surahNum);
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MushafViewerScreen(initialPage: targetPage),
              ),
            ).then((_) => _loadData());
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cardBackground,
                  AppColors.cardBackground.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // زخرفة خلفية صغيرة — Small decorative corner ornament
                Positioned(
                  top: -10,
                  right: -10,
                  child: Opacity(
                    opacity: 0.1,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: const Icon(Icons.star_border_rounded, color: AppColors.gold, size: 60),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.bookmark_rounded,
                            color: Colors.black87, size: 30),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مواصلة القراءة',
                            style: GoogleFonts.outfit(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lastRead!['surahName'] == 'المصحف'
                                ? 'آخر صفحة مفتوحة'
                                : _lastRead!['surahName'],
                            style: GoogleFonts.amiri(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lastRead!['pageNumber'] != null
                                ? 'صفحة ${_lastRead!['pageNumber']}'
                                : 'سورة ${_lastRead!['surahName']}',
                            style: GoogleFonts.amiri(
                              color: AppColors.gold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppColors.gold, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    final streak = _streakData!;
    final int currentStreak = streak['currentStreak'] ?? 0;
    final bool hasReadToday = streak['hasReadToday'] ?? false;
    final String emoji = streak['streakEmoji'] ?? '✨';
    final nextMilestone = streak['nextMilestone'] as Map<String, dynamic>;
    final List<bool> weekDays = (streak['weekDays'] as List).cast<bool>();
    final dayNames = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: 0.15),
            AppColors.gold.withValues(alpha: 0.08),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasReadToday
              ? AppColors.gold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak يوم مواظبة',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      hasReadToday
                          ? 'أحسنت! قرأت اليوم ✓'
                          : 'لم تقرأ اليوم بعد',
                      style: GoogleFonts.amiri(
                        color: hasReadToday
                            ? AppColors.emeraldLight
                            : AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isActive = weekDays[i];
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.gold
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isActive
                            ? AppColors.gold
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: isActive
                          ? const Icon(Icons.check,
                              color: Colors.black, size: 16)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayNames[i],
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(nextMilestone['emoji'] ?? '🌟',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${nextMilestone['title']} — باقي ${nextMilestone['remaining']} يوم',
                    style: GoogleFonts.amiri(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              _buildReadModeOption(
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
              _buildReadModeOption(
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

  Widget _buildReadModeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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

// ============================================================
//  PREMIUM DECORATIVE PAINTERS & WIDGETS
// ============================================================

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

  void _drawIslamicStar(Canvas canvas, Offset center, double radius, Paint paint) {
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

extension on Widget {
  Widget paddingAll(double val) => Padding(padding: EdgeInsets.all(val), child: this);
}
