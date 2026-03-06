import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/mushaf_audio_player.dart';
import '../widgets/ayah_highlighter.dart';
import '../models/ayah_coordinate.dart';
import 'download_screen.dart';

/// عارض المصحف المرئي (Mushaf Image Viewer)
/// Displays the actual scanned pages of the Quran
class MushafViewerScreen extends StatefulWidget {
  final int initialPage;

  const MushafViewerScreen({
    super.key,
    this.initialPage = 1,
  });

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen> {
  late PageController _pageController;
  int _currentPage = 1;
  bool _showAudioPlayer = false;
  String? _mushafDirPath;
  bool _isDownloaded = false;

  // رابط مصدر صور المصحف (مصحف المدينة)
  final String _imageBaseUrl =
      'https://raw.githubusercontent.com/quran/quran.com-images/master/width_1024/page';

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

  /// لجلب رابط الصورة بالتنسيق الصحيح (مثال: 001.png)
  String _getPageImageUrl(int pageNumber) {
    final paddedNumber = pageNumber.toString().padLeft(3, '0');
    return '$_imageBaseUrl$paddedNumber.png';
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
                    color: Colors.grey.withOpacity(0.3),
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
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: AppColors.cardBackground,
                            title: const Text('التفسير الميسر',
                                style: TextStyle(
                                    color: AppColors.gold,
                                    fontFamily: 'Amiri')),
                            content: Text(
                              'سيتم عرض تفسير آيات الصفحة $pageNumber هنا بعد ربط قاعدة بيانات التفسير.',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Amiri',
                                  fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إغلاق',
                                    style: TextStyle(color: AppColors.gold)),
                              ),
                            ],
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
                                builder: (context) => const DownloadScreen()),
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
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Icon(icon, color: AppColors.gold, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
        backgroundColor: AppColors.background.withOpacity(0.85),
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
            onPressed: () {
              // TODO: حفظ الصفحة كعلامة مرجعية
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
              setState(() {
                _currentPage = index + 1; // index is 0-based
                if (_showAudioPlayer) {
                  // Update audio player to new page implicitly by rebuilding it,
                  // but we might need to handle seamless playing across pages later.
                  // For now, we stop it when flipping pages:
                  _showAudioPlayer = false;
                }
              });
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
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Colors.orange, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'قم بتشغيل ملف\nlib/scripts/download_sample_assets.dart\nلجلب العينة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_isDownloaded && _mushafDirPath != null)
                        Image.file(
                          File(
                              '$_mushafDirPath/page${pageNumber.toString().padLeft(3, '0')}.png'),
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'ملف الصورة مفقود، يرجى إعادة التحميل',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: _getPageImageUrl(pageNumber),
                          fit: BoxFit.fill,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_off,
                                    color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'تأكد من اتصالك بالإنترنت\nأو قم بتحميل المصحف',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Example Highlight Overlay (Will be linked to DB later)
                      if (pageNumber == 1) // Only show mockup on page 1
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

                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.black38,
                          BlendMode.darken,
                        ),
                        child: Container(color: Colors.transparent),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Audio Player floating at the bottom
          if (_showAudioPlayer)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MushafAudioPlayer(
                pageNumber: _currentPage,
                onClose: () {
                  setState(() {
                    _showAudioPlayer = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
