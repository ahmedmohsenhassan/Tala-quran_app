import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/quran_page_helper.dart';
import '../ayah_share_card.dart';
import '../../screens/mushaf_viewer_screen.dart';

/// 🌟 مكون آية اليوم في الصفحة الرئيسية
class DailyVerseCard extends StatelessWidget {
  final Map<String, dynamic> verse;

  const DailyVerseCard({super.key, required this.verse});

  @override
  Widget build(BuildContext context) {
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
            Colors.transparent,
            AppColors.gold.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
