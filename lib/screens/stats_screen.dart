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
    if (mounted) {
      setState(() {
        _stats = stats;
        _streakData = streak;
        _completedKhatmas = khatmas;
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
        _buildStatCard('📚', '${s['totalPages']}', 'إجمالي الصفحات'),
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
                'هدف اليوم',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$todayPages / 5 صفحات',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 14,
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
              '🎉 أحسنت! أتممت هدفك اليوم',
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
}
