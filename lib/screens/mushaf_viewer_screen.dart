import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/mushaf_audio_player.dart';
import '../widgets/ayah_highlighter.dart';
import '../models/ayah_coordinate.dart';
import '../services/bookmark_service.dart';
import '../utils/quran_page_helper.dart';
import 'download_screen.dart';
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

  /// إظهار الخيارات السفلية عند الضغط على الصفحة
  void _showPageOptions(BuildContext context, int pageNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'خيارات الصفحة $pageNumber',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    _buildOptionButton(
                      icon: Icons.play_arrow,
                      label: 'تشغيل',
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _showAudioPlayer = true;
                        });
                      },
                    ),
                    _buildOptionButton(
                      icon: Icons.menu_book,
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
                      icon: Icons.bookmark_add,
                      label: 'حفظ',
                      onTap: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم حفظ الصفحة $pageNumber في العلامات المرجعية.',
                              style: const TextStyle(fontFamily: 'Amiri'),
                            ),
                            backgroundColor: AppColors.gold,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    if (!_isDownloaded)
                      _buildOptionButton(
                        icon: Icons.download,
                        label: 'تحميل',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DownloadScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(icon, color: AppColors.gold, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.85),
        elevation: 0,
        title: Text(
          'صفحة $_currentPage',
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 20,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.gold),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () async {
              await BookmarkService.addPageBookmark(pageNumber: _currentPage);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم حفظ الصفحة $_currentPage في العلامات المرجعية.',
                    style: const TextStyle(fontFamily: 'Amiri'),
                  ),
                  backgroundColor: AppColors.gold,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            reverse: true,
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
                      Container(color: const Color(0xFFFFFDF5)),
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

  Widget _buildPlaceholder(int pageNumber) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.2),
          width: 20,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 100,
                color: AppColors.gold,
              ),
              const SizedBox(height: 32),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'صفحة $pageNumber',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 28,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'مقطع من المصحف الشريف',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'عينة تجريبية: الصفحة قيد التحميل حالياً.\nيمكنك الاستمرار في تصفح التطبيق وتجربة الميزات.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontFamily: 'Amiri',
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
