import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/juz_data.dart';
import '../utils/app_colors.dart';
import 'mushaf_viewer_screen.dart';

/// شاشة فهرس الأجزاء والأحزاب — Juz & Hizb Index Screen
class JuzHizbScreen extends StatefulWidget {
  const JuzHizbScreen({super.key});

  @override
  State<JuzHizbScreen> createState() => _JuzHizbScreenState();
}

class _JuzHizbScreenState extends State<JuzHizbScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.bg(context),
              centerTitle: true,
              title: Text(
                'الأجزاء والأحزاب',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardBackground
                        : AppColors.lightEmeraldSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textMut(context),
                    labelStyle: GoogleFonts.amiri(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: GoogleFonts.amiri(fontSize: 14),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '📖 الأجزاء'),
                      Tab(text: '📑 الأحزاب'),
                    ],
                  ),
                ),
              ),
            ),

            // Tab content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildJuzList(context),
                  _buildHizbList(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  قائمة الأجزاء (30 جزء)
  // ============================================================
  Widget _buildJuzList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juz = JuzData.juzList[index];
        final juzName = JuzData.juzNames[index];

        return _JuzCard(
          number: juz.number,
          name: juzName,
          startSurah: juz.startSurah,
          startAyah: juz.startAyah,
          startPage: juz.startPage,
          endPage: index < 29 ? JuzData.juzList[index + 1].startPage - 1 : 604,
          onTap: () => _goToPage(context, juz.startPage),
        );
      },
    );
  }

  // ============================================================
  //  قائمة الأحزاب (60 حزب)
  // ============================================================
  Widget _buildHizbList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      physics: const BouncingScrollPhysics(),
      itemCount: 60,
      itemBuilder: (context, index) {
        final hizbNumber = index + 1;
        final juzNumber = ((index) ~/ 2) + 1;
        final isFirstHalf = index % 2 == 0;
        final juz = JuzData.juzList[juzNumber - 1];

        // approximate hizb start page
        final juzStartPage = juz.startPage;
        final juzEndPage =
            juzNumber < 30 ? JuzData.juzList[juzNumber].startPage - 1 : 604;
        final hizbStartPage = isFirstHalf
            ? juzStartPage
            : juzStartPage + ((juzEndPage - juzStartPage + 1) ~/ 2);

        return _HizbCard(
          hizbNumber: hizbNumber,
          juzNumber: juzNumber,
          isFirstHalf: isFirstHalf,
          startPage: hizbStartPage,
          onTap: () => _goToPage(context, hizbStartPage),
        );
      },
    );
  }

  void _goToPage(BuildContext context, int page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafViewerScreen(initialPage: page),
      ),
    );
  }
}

// ============================================================
//  بطاقة الجزء — Juz Card
// ============================================================
class _JuzCard extends StatelessWidget {
  final int number;
  final String name;
  final String startSurah;
  final int startAyah;
  final int startPage;
  final int endPage;
  final VoidCallback onTap;

  const _JuzCard({
    required this.number,
    required this.name,
    required this.startSurah,
    required this.startAyah,
    required this.startPage,
    required this.endPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : AppColors.gold.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // رقم الجزء في دائرة ذهبية
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.2),
                        AppColors.gold.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // محتوى البطاقة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الجزء $number',
                        style: GoogleFonts.amiri(
                          color: AppColors.text(context),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: GoogleFonts.amiri(
                          color: AppColors.gold.withValues(alpha: 0.8),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يبدأ من: $startSurah - آية $startAyah',
                        style: GoogleFonts.amiri(
                          color: AppColors.textMut(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // رقم الصفحة
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ص $startPage',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$startPage - $endPage',
                      style: GoogleFonts.amiri(
                        color: AppColors.textMut(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  بطاقة الحزب — Hizb Card
// ============================================================
class _HizbCard extends StatelessWidget {
  final int hizbNumber;
  final int juzNumber;
  final bool isFirstHalf;
  final int startPage;
  final VoidCallback onTap;

  const _HizbCard({
    required this.hizbNumber,
    required this.juzNumber,
    required this.isFirstHalf,
    required this.startPage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // علامة الحزب
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirstHalf
                        ? AppColors.gold.withValues(alpha: 0.12)
                        : AppColors.emeraldLight.withValues(alpha: 0.2),
                    border: Border.all(
                      color: isFirstHalf
                          ? AppColors.gold.withValues(alpha: 0.4)
                          : AppColors.emeraldLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$hizbNumber',
                      style: GoogleFonts.amiri(
                        color: isFirstHalf ? AppColors.gold : AppColors.emeraldLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحزب $hizbNumber',
                        style: GoogleFonts.amiri(
                          color: AppColors.text(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'الجزء $juzNumber — ${isFirstHalf ? "النصف الأول" : "النصف الثاني"}',
                        style: GoogleFonts.amiri(
                          color: AppColors.textMut(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  'ص $startPage',
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.gold.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
