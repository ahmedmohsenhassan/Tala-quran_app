import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../utils/app_colors.dart';

/// 📖 مكون تتبع التقدم في الختمة
class KhatmaProgressCard extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final double progress;
  final String percent;
  final GlobalKey showcaseKey;

  const KhatmaProgressCard({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.percent,
    required this.showcaseKey,
  });

  @override
  Widget build(BuildContext context) {
    // Milestone data
    final milestones = [
      {'page': 151, 'label': '¼', 'achieved': currentPage >= 151},
      {'page': 302, 'label': '½', 'achieved': currentPage >= 302},
      {'page': 453, 'label': '¾', 'achieved': currentPage >= 453},
      {'page': 604, 'label': 'ختم', 'achieved': currentPage >= 604},
    ];

    return Showcase(
      key: showcaseKey,
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
}
