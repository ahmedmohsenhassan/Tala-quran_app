import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../data/rub_data.dart';
import '../../screens/mushaf_viewer_screen.dart';

/// 📖 مكون قائمة الأجزاء والأرباع في الصفحة الرئيسية
class JuzTabContent extends StatelessWidget {
  const JuzTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    const List<QuranQuarter> quarters = RubData.quarters;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: quarters.length,
      itemBuilder: (context, index) {
        final quarter = quarters[index];
        final bool showHeader =
            index == 0 || quarters[index - 1].juz != quarter.juz;

        return Column(
          children: [
            if (showHeader) _buildSectionHeader('جزء ${quarter.juz}'),
            _buildRubCard(context, quarter),
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

  Widget _buildRubCard(BuildContext context, QuranQuarter rub) {
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
                      '${rub.surahName} - الربع ${rub.quarterInHizb}',
                      style: GoogleFonts.amiri(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      'صفحة ${rub.page}',
                      style: GoogleFonts.outfit(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.gold, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
