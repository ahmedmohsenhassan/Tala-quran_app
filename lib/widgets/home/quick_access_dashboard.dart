import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../utils/app_colors.dart';
import '../../services/firebase_khatma_service.dart';
import '../../screens/shared_khatma_hub_screen.dart';
import '../../screens/smart_hifz_screen.dart';
import '../../screens/reading_plan_screen.dart';
import '../../screens/stats_screen.dart';
import '../../screens/mushaf_viewer_screen.dart';
import '../premium_card_frame.dart';
import 'juz_progress_card.dart';

/// ⚡ لوحة الوصول السريع في الصفحة الرئيسية
class QuickAccessDashboard extends StatelessWidget {
  final Map<String, dynamic>? statsData;
  final Map<String, dynamic>? streakData;
  final Map<String, dynamic>? lastRead;
  final VoidCallback onRefresh;
  final GlobalKey statsKey;
  final GlobalKey continueReadingKey;

  const QuickAccessDashboard({
    super.key,
    required this.statsData,
    required this.streakData,
    required this.lastRead,
    required this.onRefresh,
    required this.statsKey,
    required this.continueReadingKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSharedKhatmaCard(context),
          const SizedBox(width: 16),
          if (lastRead != null) ...[
            PremiumCardFrame(
              child: JuzProgressCard(lastRead: lastRead!, onRefresh: onRefresh),
            ),
            const SizedBox(width: 16),
          ],
          PremiumCardFrame(child: _buildSmartHifzCard(context)),
          const SizedBox(width: 16),
          PremiumCardFrame(child: _buildKhatmaCard(context)),
          const SizedBox(width: 16),
          if (statsData != null) ...[
            PremiumCardFrame(child: _buildSmartStatsCard(context)),
            const SizedBox(width: 16),
          ],
          if (streakData != null) ...[
            PremiumCardFrame(child: _buildStreakCard(streakData!)),
            const SizedBox(width: 16),
          ],
          if (lastRead != null)
            PremiumCardFrame(child: _buildLastReadCard(context)),
        ],
      ),
    );
  }

  Widget _buildSharedKhatmaCard(BuildContext context) {
    final firebaseKhatma =
        Provider.of<FirebaseKhatmaService>(context, listen: false);

    return StreamBuilder<List<SharedKhatma>>(
      stream: firebaseKhatma.streamMyKhatmas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return PremiumCardFrame(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SharedKhatmaHubScreen()),
                );
              },
              child: Container(
                width: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1A808000), // GOLD DARK 10%
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x4DFFD700)), // GOLD 30%
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_add_rounded,
                        color: AppColors.gold, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'ختمة جماعية',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تنافس مع الآخرين',
                      style: GoogleFonts.amiri(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final khatma = snapshot.data!.first;
        double aggregateProgress = 0.0;
        if (khatma.progress.isNotEmpty) {
          int totalPagesRead = khatma.progress.values.reduce((a, b) => a + b);
          aggregateProgress = (totalPagesRead / 604).clamp(0.0, 1.0);
        }
        final totalParticipants = khatma.participants.length;

        return PremiumCardFrame(
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.groups_rounded,
                        color: AppColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        khatma.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (int i = 0; i < (totalParticipants > 3 ? 3 : totalParticipants); i++)
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 1),
                        ),
                        child: const Icon(Icons.person, size: 14, color: AppColors.gold),
                      ),
                    if (totalParticipants > 3)
                      Text('+${totalParticipants - 3}', 
                        style: const TextStyle(color: AppColors.gold, fontSize: 10)),
                  ],
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: aggregateProgress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  minHeight: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartHifzCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmartHifzScreen()),
      ).then((_) => onRefresh()),
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
                const Icon(Icons.psychology_rounded,
                    color: AppColors.gold, size: 24),
                const SizedBox(width: 8),
                Text('المساعد الذكي',
                    style: GoogleFonts.amiri(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text('اختبر حفظك الآن',
                style: GoogleFonts.amiri(
                    color: AppColors.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildKhatmaCard(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
      ).then((_) => onRefresh()),
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
                style: GoogleFonts.amiri(
                    color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartStatsCard(BuildContext context) {
    final stats = statsData!;
    final double progress = stats['dailyGoalProgress'] ?? 0.0;
    final int todayPages = stats['todayPages'] ?? 0;

    return Showcase(
      key: statsKey,
      title: 'إحصائياتك الذكية ⚡',
      description: 'لوحة تحكمك الكاملة: خريطة حرارية وإحصائيات مفصلة لأدائك.',
      tooltipBackgroundColor: AppColors.cardBackground,
      textColor: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatsScreen()),
        ).then((_) => onRefresh()),
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
                  const Icon(Icons.auto_graph_rounded,
                      color: AppColors.gold, size: 20),
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
                      style: GoogleFonts.amiri(
                          color: AppColors.textMuted, fontSize: 11)),
                  Text('${(progress * 100).toInt()}%',
                      style: GoogleFonts.outfit(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> streak) {
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
                  color: hasReadToday
                      ? AppColors.emeraldLight
                      : AppColors.textMuted,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLastReadCard(BuildContext context) {
    return Showcase(
      key: continueReadingKey,
      title: 'إكمال القراءة 📖',
      description: 'بضغطة واحدة، عُد إلى نفس الصفحة التي توقفت عندها.',
      tooltipBackgroundColor: AppColors.cardBackground,
      textColor: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MushafViewerScreen(initialPage: lastRead!['pageNumber']),
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
                  Text(lastRead!['surahName'] ?? 'الفاتحة',
                      style: GoogleFonts.amiri(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text('آخر تلاوة: صفحة ${lastRead!['pageNumber']}',
                  style: GoogleFonts.amiri(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
