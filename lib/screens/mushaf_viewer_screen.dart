import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/mushaf_audio_player.dart';
import '../widgets/ayah_highlighter.dart';
import '../models/ayah_coordinate.dart';
import '../services/bookmark_service.dart';
import '../utils/quran_page_helper.dart';
import 'tafseer_screen.dart';

/// عارض المصحف المرئي (Mushaf Image Viewer)
/// Displays the actual scanned pages of the Quran
class MushafViewerScreen extends StatefulWidget {
  final int initialPage;

  const MushafViewerScreen({super.key, this.initialPage = 1});

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showAudioPlayer = false;
  String? _mushafDirPath;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    // PageView uses 0-based index, but Quran pages are 1-604
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _initMushafDir();
  }

  Future<void> _initMushafDir() async {
    final prefs = await SharedPreferences.getInstance();
    final isDownloaded = prefs.getBool('mushaf_downloaded') ?? false;

    if (isDownloaded) {
      final dir = await getApplicationDocumentsDirectory();
      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _mushafDirPath = '${dir.path}/mushaf_pages';
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPageOptions(BuildContext context, int pageNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'خيارات الصفحة $pageNumber',
                  style: GoogleFonts.amiri(
                    color: AppColors.emerald,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'تشغيل',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _showAudioPlayer = true);
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.menu_book_rounded,
                      label: 'التفسير',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TafseerScreen(
                              surahNumber:
                                  QuranPageHelper.getSurahForPage(pageNumber),
                              ayahNumber: 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.bookmark_add_rounded,
                      label: 'حفظ',
                      onTap: () async {
                        Navigator.pop(context);
                        await BookmarkService.addPageBookmark(
                            pageNumber: pageNumber);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حفظ الصفحة $pageNumber في العلامات.',
                              style: GoogleFonts.amiri(),
                            ),
                            backgroundColor: AppColors.emerald,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon, color: AppColors.emerald, size: 28),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.amiri(
            color: AppColors.emerald,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pageController,
              itemCount: 604,
              onPageChanged: (index) {
                final page = index + 1;
                setState(() {
                  _currentPage = page;
                  if (_showAudioPlayer) {
                    _showAudioPlayer = false;
                  }
                });
                BookmarkService.saveLastRead(
                  surahNumber: 0,
                  surahName: 'المصحف',
                  pageNumber: page,
                );
              },
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                return GestureDetector(
                  onTap: () {
                    _showPageOptions(context, pageNumber);
                  },
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: AppColors.cream),
                        if (pageNumber <= 5)
                          Image.asset(
                            'assets/mushaf/page${pageNumber.toString().padLeft(3, '0')}.png',
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(pageNumber),
                          )
                        else if (_isDownloaded && _mushafDirPath != null)
                          Image.file(
                            File(
                              '$_mushafDirPath/page${pageNumber.toString().padLeft(3, '0')}.png',
                            ),
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholder(pageNumber),
                          )
                        else
                          _buildPlaceholder(pageNumber),

                        // Example Highlight Overlay
                        if (pageNumber == 1)
                          AyahHighlighter(
                            coordinates: [
                              AyahCoordinate(
                                surahNumber: 1,
                                ayahNumber: 1,
                                pageNumber: 1,
                                minX: 153,
                                maxX: 866,
                                minY: 341,
                                maxY: 462,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Top Bar
          _buildFloatingTopBar(),

          if (_showAudioPlayer)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MushafAudioPlayer(
                pageNumber: _currentPage,
                onClose: () => setState(() => _showAudioPlayer = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.gold, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Text(
                  'صفحة $_currentPage',
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined,
                      color: AppColors.gold),
                  onPressed: () async {
                    await BookmarkService.addPageBookmark(
                        pageNumber: _currentPage);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حفظ الصفحة $_currentPage',
                            style: GoogleFonts.amiri()),
                        backgroundColor: AppColors.emerald,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(int pageNumber) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.1),
          width: 20,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: AppColors.emerald,
              ),
              const SizedBox(height: 24),
              Text(
                'صفحة $pageNumber',
                style: GoogleFonts.amiri(
                  color: AppColors.emerald,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الآن في تطبيق تلا\nنظام بدائل ذكي للقراءة المتصلة',
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  color: AppColors.emerald.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
