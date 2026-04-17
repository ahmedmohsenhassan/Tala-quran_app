import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/quran_page_helper.dart';
import '../premium_painters.dart';
import '../../screens/mushaf_viewer_screen.dart';

/// 🏅 مكون حلقة التقدم في الجزء الحالي
class JuzProgressCard extends StatelessWidget {
  final Map<String, dynamic> lastRead;
  final VoidCallback onRefresh;

  const JuzProgressCard({
    super.key,
    required this.lastRead,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final currentPage = lastRead['pageNumber'] as int? ?? 1;
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
      ).then((_) => onRefresh()),
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
                painter: JuzProgressPainter(
                  progress: progress,
                  trackColor: AppColors.gold.withValues(alpha: 0.1),
                  progressColor: AppColors.gold,
                ),
                child: Center(
                  child: Text(
                    percentText,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'أنهيت $pagesIntoJuz من $juzTotalPages صفحة',
              style: GoogleFonts.amiri(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
