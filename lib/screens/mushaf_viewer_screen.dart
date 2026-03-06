import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../widgets/mushaf_audio_player.dart';

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

  // رابط مصدر صور المصحف (مصحف المدينة - مجمع الملك فهد)
  // Quran images base URL (Madinah Mushaf)
  final String _imageBaseUrl = 'https://quran-images-api.vercel.app/hq/page';

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    // PageView uses 0-based index, but Quran pages are 1-604
    _pageController = PageController(initialPage: widget.initialPage - 1);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                            title: const Text('التفسير الميسر', style: TextStyle(color: AppColors.gold, fontFamily: 'Amiri')),
                            content: Text(
                              'سيتم عرض تفسير آيات الصفحة $pageNumber هنا بعد ربط قاعدة بيانات التفسير.',
                              style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Amiri', fontSize: 16),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إغلاق', style: TextStyle(color: AppColors.gold)),
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
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
                        CachedNetworkImage(
                          imageUrl: _getPageImageUrl(pageNumber),
                          fit: BoxFit.fill,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.wifi_off, color: Colors.grey, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'تأكد من اتصالك بالإنترنت',
                                  style: TextStyle(color: Colors.grey, fontSize: 18),
                                ),
                              ],
                            ),
                          ),
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
      ),
    ),
  }
}
