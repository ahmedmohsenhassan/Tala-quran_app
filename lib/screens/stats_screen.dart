import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/reading_stats_service.dart';
import '../services/streak_service.dart';
import '../services/khatma_service.dart';
import '../utils/app_colors.dart';
import 'khatma_screen.dart';

/// شاشة الإحصائيات — Stats Screen
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _streakData;
  Map<String, int>? _monthData;
  int _completedKhatmas = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await ReadingStatsService.getStats();
    final streak = await StreakService.getStreakData();
    final khatmas = await KhatmaService.getCompletedCount();
    final monthData = await ReadingStatsService.getMonthData();
    if (mounted) {
      setState(() {
        _stats = stats;
        _streakData = streak;
        _completedKhatmas = khatmas;
        _monthData = monthData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'الإحصائيات الذكية',
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.auto_stories_rounded, color: AppColors.gold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KhatmaScreen()),
              );
            },
          ),
        ],
      ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الوعاء العلوي - ملخص ذكي
                    _buildSmartSummaryHeader(),
                    const SizedBox(height: 24),

                    // الإحصائيات السريعة — Quick stats grid
                    _buildQuickStats(),
                    const SizedBox(height: 32),

                    // رسم الأسبوع — Weekly chart
                    Row(
                      children: [
                        const Icon(Icons.show_chart_rounded, color: AppColors.gold, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'نشاط الأسبوع الذكي',
                          style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildWeekChart(),
                    const SizedBox(height: 32),

                    // هدف اليوم — Today's goal
                    _buildTodayGoal(),
                    const SizedBox(height: 24),

                    // إنجاز الـ Streak — Milestone celebration
                    _buildMilestoneCelebration(),
                    const SizedBox(height: 32),

                    // الخريطة الحرارية — 30-Day Reading Heatmap
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.gold, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'خريطة المواظبة (30 يوم)',
                          style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMonthHeatmap(),
                    const SizedBox(height: 80),
                  ],
                ),
      ),
    );
  }

  Widget _buildSmartSummaryHeader() {
    final s = _stats!;
    final totalProgress = (s['totalPages'] / 604).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emerald,
            AppColors.emerald.withValues(alpha: 0.8),
            AppColors.gold.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي الختمة',
                    style: GoogleFonts.amiri(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${(totalProgress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 40),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لقد قرأت ${s['totalPages']} من أصل 604 صفحة',
            style: GoogleFonts.amiri(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final s = _stats!;
    final streak = _streakData!;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('📖', '${s['todayPages']}', 'صفحات اليوم'),
        _buildStatCard('🔥', '${streak['currentStreak']}', 'أيام المواظبة'),
        _buildStatCard('⏱️', _formatMinutes(s['totalSessionMinutes'] ?? 0), 'وقت القراءة'),
        _buildStatCard('🏆', '$_completedKhatmas', 'ختمات مكتملة'),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: AppColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.amiri(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  Widget _buildWeekChart() {
    final weekData = (_stats!['weekData'] as List<int>);
    final maxVal = weekData.reduce(max).clamp(1, 999);
    final dayLabels = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final val = weekData[i];
            final height = maxVal > 0 ? (val / maxVal) * 120 : 0.0;
            final isToday = i == 6;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$val',
                      style: GoogleFonts.outfit(
                        color: isToday ? AppColors.gold : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: height.clamp(4, 120),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: isToday
                              ? [
                                  AppColors.gold,
                                  AppColors.gold.withValues(alpha: 0.6)
                                ]
                              : [
                                  AppColors.emerald.withValues(alpha: 0.6),
                                  AppColors.emerald.withValues(alpha: 0.3),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dayLabels[i],
                      style: GoogleFonts.outfit(
                        color: isToday ? AppColors.gold : AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTodayGoal() {
    final progress = _stats!['dailyGoalProgress'] as double;
    final todayPages = _stats!['todayPages'] as int;
    final dailyGoal = _stats!['dailyGoal'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: 0.1),
            AppColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'هدف اليوم (الوِرد)',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showGoalPicker(dailyGoal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '$todayPages / $dailyGoal صفحات',
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.gold : AppColors.emeraldLight,
              ),
            ),
          ),
          if (progress >= 1.0) ...[
            const SizedBox(height: 12),
            Text(
              '🎉 أحسنت! أتممت وِردك اليوم',
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ============================================================
  //  30-DAY READING HEATMAP 📅✨
  // ============================================================
  Widget _buildMonthHeatmap() {
    if (_monthData == null) return const SizedBox();

    final entries = _monthData!.entries.toList();
    final maxPages = entries.map((e) => e.value).fold<int>(1, (a, b) => a > b ? a : b);
    final dayLabels = ['سب', 'أح', 'إث', 'ثل', 'أر', 'خم', 'جم'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Day labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels.map((label) => SizedBox(
              width: 36,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Grid of day cells
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.start,
            children: entries.map((entry) {
              final pages = entry.value;
              final intensity = maxPages > 0 ? (pages / maxPages).clamp(0.0, 1.0) : 0.0;
              final date = DateTime.parse(entry.key);
              final isToday = entry.key == entries.last.key;

              Color cellColor;
              if (pages == 0) {
                cellColor = Colors.white.withValues(alpha: 0.03);
              } else if (intensity < 0.3) {
                cellColor = AppColors.emerald.withValues(alpha: 0.25);
              } else if (intensity < 0.6) {
                cellColor = AppColors.emerald.withValues(alpha: 0.5);
              } else if (intensity < 0.85) {
                cellColor = AppColors.gold.withValues(alpha: 0.5);
              } else {
                cellColor = AppColors.gold.withValues(alpha: 0.85);
              }

              return Tooltip(
                message: '${date.day}/${date.month} — $pages صفحة',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.gold, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: GoogleFonts.outfit(
                        color: pages > 0
                            ? Colors.white
                            : AppColors.textMuted.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(Colors.white.withValues(alpha: 0.03), 'لم يُقرأ'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.emerald.withValues(alpha: 0.4), 'قليل'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.gold.withValues(alpha: 0.5), 'جيد'),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.gold.withValues(alpha: 0.85), 'ممتاز'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  // ============================================================
  //  WIRD GOAL PICKER 🎯✨
  // ============================================================
  void _showGoalPicker(int currentGoal) {
    double sliderValue = currentGoal.toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(
                    top: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '📖 اختر وِردك اليومي',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${sliderValue.round()} صفحة يومياً',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getWirdDescription(sliderValue.round()),
                      style: GoogleFonts.amiri(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.gold,
                        inactiveTrackColor: AppColors.gold.withValues(alpha: 0.15),
                        thumbColor: AppColors.gold,
                        overlayColor: AppColors.gold.withValues(alpha: 0.1),
                        trackHeight: 6,
                      ),
                      child: Slider(
                        value: sliderValue,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        onChanged: (v) => setModalState(() => sliderValue = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                        Text('20', style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await ReadingStatsService.setDailyGoal(sliderValue.round());
                          if (mounted) {
                            Navigator.pop(context);
                            _loadData(); // Refresh stats
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          'تثبيت الوِرد',
                          style: GoogleFonts.amiri(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getWirdDescription(int pages) {
    if (pages <= 2) return 'وِرد خفيف — للمبتدئين ✨';
    if (pages <= 5) return 'وِرد معتدل — ختمة كل 4 أشهر 📚';
    if (pages <= 10) return 'وِرد قوي — ختمة كل شهرين 🔥';
    if (pages <= 15) return 'وِرد مجتهد — ختمة كل 40 يوم 🏆';
    return 'وِرد الأبطال — ختمة كل شهر! 👑';
  }

  // ============================================================
  //  MILESTONE CELEBRATION 🏆✨
  // ============================================================
  Widget _buildMilestoneCelebration() {
    final streak = _streakData!;
    final milestone = streak['nextMilestone'] as Map<String, dynamic>;
    final currentStreak = streak['currentStreak'] as int;
    final emoji = streak['streakEmoji'] as String;
    final remaining = milestone['remaining'] as int;
    final target = milestone['target'] as int;
    final title = milestone['title'] as String;
    final milestoneEmoji = milestone['emoji'] as String;
    final progress = currentStreak / target;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.12),
            AppColors.emerald.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإنجاز القادم: $title',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'باقي $remaining يوم $milestoneEmoji',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          if (currentStreak > 0) ...[
            const SizedBox(height: 10),
            Text(
              _getMotivationalMessage(currentStreak),
              style: GoogleFonts.amiri(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _getMotivationalMessage(int streak) {
    if (streak >= 100) return '🌟 ما شاء الله! أنت قدوة في المثابرة.';
    if (streak >= 30) return '🏆 شهر كامل من المواظبة! استمر.';
    if (streak >= 7) return '🔥 أسبوع متواصل! الله يبارك فيك.';
    if (streak >= 3) return '✨ بداية موفقة، لا تتوقف!';
    return '💪 ابدأ اليوم، كل رحلة تبدأ بخطوة.';
  }
}
