import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surahs.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import '../services/bookmark_service.dart';
import 'mushaf_viewer_screen.dart';
import 'surah_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final lastRead = await BookmarkService.getLastRead();
    if (mounted) {
      setState(() {
        _lastRead = lastRead;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildWelcomeHeader(),
                    const SizedBox(height: 32),
                    if (_lastRead != null) ...[
                      _buildQuickAccessSection(),
                      const SizedBox(height: 32),
                    ],
                    Text(
                      'الفهرس الشامل',
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final surah = surahs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SurahCard(
                        number: surah['number'],
                        name: surah['name'],
                        englishName: surah['english_name'],
                        onTap: () => _showReadModeDialog(context, surah),
                      ),
                    );
                  },
                  childCount: surahs.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.background,
      centerTitle: true,
      title: Text(
        'تلا قرآن',
        style: GoogleFonts.amiri(
          color: AppColors.gold,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            bottom: -20,
            child: Icon(Icons.mosque,
                color: Colors.white.withValues(alpha: 0.05), size: 120),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: AppColors.gold.withValues(alpha: 0.8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'السلام عليكم',
                    style: GoogleFonts.amiri(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'نور حياتك بالقرآن',
                style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.gold, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'جمعة مباركة',
                      style: GoogleFonts.amiri(
                          color: AppColors.gold, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'متابعة الورد اليومي',
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(Icons.history_rounded,
                color: AppColors.gold.withValues(alpha: 0.5), size: 18),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            final page = _lastRead!['pageNumber'] ??
                QuranPageHelper.getPageForSurah(_lastRead!['surahNumber']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MushafViewerScreen(initialPage: page),
              ),
            ).then((_) => _loadLastRead());
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.emerald.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.menu_book_rounded,
                        color: AppColors.emerald, size: 28),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _lastRead!['surahName'] == 'المصحف'
                            ? 'آخر صفحة مفتوحة'
                            : _lastRead!['surahName'],
                        style: GoogleFonts.amiri(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastRead!['pageNumber'] != null
                            ? 'صفحة ${_lastRead!['pageNumber']}'
                            : 'سورة ${_lastRead!['surahName']}',
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.gold, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReadModeDialog(BuildContext context, Map<String, dynamic> surah) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'سورة ${surah['name']}',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildReadModeOption(
                icon: Icons.menu_book_rounded,
                title: 'قراءة من المصحف',
                subtitle: 'تجربة بصرية كلاسيكية',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MushafViewerScreen(
                        initialPage:
                            QuranPageHelper.getPageForSurah(surah['number']),
                      ),
                    ),
                  ).then((_) => _loadLastRead());
                },
              ),
              const SizedBox(height: 12),
              _buildReadModeOption(
                icon: Icons.text_snippet_rounded,
                title: 'قراءة نصية حديثة',
                subtitle: 'خطوط واضحة ونظام تصفح سريع',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(
                        surahNumber: surah['number'],
                        surahName: surah['name'],
                      ),
                    ),
                  ).then((_) => _loadLastRead());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadModeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style:
                        GoogleFonts.amiri(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }
}
