import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surahs.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import '../services/bookmark_service.dart';
import 'mushaf_viewer_screen.dart';
import 'surah_detail_screen.dart';

/// الشاشة الرئيسية - قائمة السور والتفاعل السريع
/// Home Screen - Surah list and Quick Access
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
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            if (_lastRead != null) ...[
              _buildQuickAccessSection(),
              const SizedBox(height: 32),
            ],
            Text(
              'كل السور',
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(surahs.length, (index) {
              final surah = surahs[index];
              return SurahCard(
                number: surah['number'],
                name: surah['name'],
                englishName: surah['english_name'],
                onTap: () {
                  _showReadModeDialog(context, surah);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'السلام عليكم',
                    style: GoogleFonts.amiri(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'أهلاً بك مجدداً',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.mosque, color: Colors.white, size: 48),
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
        Text(
          'متابعة القراءة',
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            final page = _lastRead!['pageNumber'] ??
                QuranPageHelper.getPageForSurah(_lastRead!['surahNumber']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MushafViewerScreen(
                  initialPage: page,
                ),
              ),
            ).then((_) => _loadLastRead());
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history,
                      color: AppColors.gold, size: 28),
                ),
                const SizedBox(width: 16),
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
                      Text(
                        _lastRead!['pageNumber'] != null
                            ? 'صفحة ${_lastRead!['pageNumber']}'
                            : 'سورة ${_lastRead!['surahName']}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.gold, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReadModeDialog(BuildContext context, Map<String, dynamic> surah) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            'اختر طريقة القراءة',
            style: GoogleFonts.amiri(
                color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book, color: AppColors.gold),
                title: const Text('قراءة من المصحف',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('عرض صفحات مصورة (تحتاج تحميل)',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.text_format, color: AppColors.gold),
                title: const Text('قراءة نصية',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('عرض آيات مكتوبة (تعمل دائماً)',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
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
}
