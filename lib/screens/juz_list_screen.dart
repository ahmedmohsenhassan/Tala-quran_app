import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';
import '../data/juzs.dart'; // We'll need to create this data file
import '../utils/quran_page_helper.dart';
import 'mushaf_viewer_screen.dart';

class JuzListScreen extends StatelessWidget {
  const JuzListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.background,
              centerTitle: true,
              title: Text(
                'فهرس الأجزاء',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final juzNumber = index + 1;
                    final startPage = QuranPageHelper.getPageForJuz(juzNumber);
                    final juzInfo = juzsData[index];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _JuzCard(
                        juzNumber: juzNumber,
                        juzInfo: juzInfo,
                        startPage: startPage,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MushafViewerScreen(initialPage: startPage),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: 30, // القرآن 30 جزء
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)), // مساحة إضافية للبار السفلي
          ],
        ),
      ),
    );
  }
}

class _JuzCard extends StatelessWidget {
  final int juzNumber;
  final Map<String, dynamic> juzInfo;
  final int startPage;
  final VoidCallback onTap;

  const _JuzCard({
    required this.juzNumber,
    required this.juzInfo,
    required this.startPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // رقم الجزء (تصميم بريميوم)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      '$juzNumber',
                      style: GoogleFonts.outfit(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                
                // التفاصيل
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الجزء ${juzInfo['name_ar']}',
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'سورة ${juzInfo['start_surah']} - آية ${juzInfo['start_ayah']}',
                        style: GoogleFonts.amiri(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // رقم الصفحة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'صفحة $startPage',
                    style: GoogleFonts.outfit(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
