import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/quran_page_helper.dart';
import '../../data/surah_metadata.dart';
import '../surah_card.dart';
import '../../screens/mushaf_viewer_screen.dart';

/// 📜 مكون قائمة السور في الصفحة الرئيسية
class SurahTabContent extends StatelessWidget {
  final VoidCallback onRefresh;

  const SurahTabContent({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MushafViewerScreen(
                      initialPage: surah['pageNumber']!,
                    ),
                  ),
                ).then((_) => onRefresh());
              },
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
}
