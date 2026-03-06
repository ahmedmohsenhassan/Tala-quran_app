import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surahs.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import 'mushaf_viewer_screen.dart';

/// الشاشة الرئيسية - قائمة السور
/// Home Screen - Surah list
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'تلا قرآن',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          itemCount: surahs.length,
          itemBuilder: (context, index) {
            final surah = surahs[index];
            return SurahCard(
              number: surah['number'],
              name: surah['name'],
              englishName: surah['english_name'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MushafViewerScreen(
                      initialPage: QuranPageHelper.getPageForSurah(surah['number']),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
