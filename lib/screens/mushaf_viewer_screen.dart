import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../widgets/mushaf_audio_player.dart';
import '../services/bookmark_service.dart';
import '../services/streak_service.dart';
import '../services/reading_stats_service.dart';
import '../services/khatma_service.dart';
import '../utils/quran_page_helper.dart';
import '../services/ayah_sync_service.dart';
import '../services/reading_service.dart';
import '../models/ayah_coordinate.dart';
import '../widgets/ayah_highlighter.dart';
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
  String _currentReading = ReadingService.hafs;
  bool _isDownloaded = false;
  bool _showBars = true;
  bool _isLoading = true;
  String _currentSurahName = '';
  int _currentJuz = 1;
  
  // Highlighting state
  int? _activeSurah;
  int? _activeAyah;
  List<AyahCoordinate> _pageCoordinates = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _loadPageData(widget.initialPage);
    // تأكد من أن حالة النظام طبيعية في البداية — Default to edge-to-edge
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _initMushafDir() async {
    final prefs = await SharedPreferences.getInstance();
    _currentReading = await ReadingService.getSelectedReading();
    
    // Check if the specific reading is downloaded
    final isDownloaded = prefs.getBool('mushaf_downloaded_${_currentReading == ReadingService.hafs ? 'hafs' : 'warsh'}') ?? 
                        (prefs.getBool('mushaf_downloaded') ?? false); // Fallback for old version

    if (isDownloaded) {
      final dir = await getApplicationDocumentsDirectory();
      final readingFolder = _currentReading == ReadingService.hafs ? 'mushaf_hafs' : 'mushaf_warsh';
      
      // Fallback for old single-folder structure
      final oldDir = Directory('${dir.path}/mushaf_pages');
      final newDir = Directory('${dir.path}/$readingFolder');
      
      final finalPath = (await newDir.exists()) ? newDir.path : oldDir.path;

      if (mounted) {
        setState(() {
          _isDownloaded = true;
          _mushafDirPath = finalPath;
        });
      }
    } else {
      setState(() {
        _isDownloaded = false;
        _mushafDirPath = null;
      });
    }
  }

  Future<void> _loadPageData(int pageNumber) async {
    setState(() => _isLoading = true);
    await _initMushafDir();
    _currentSurahName = QuranPageHelper.getSurahNameForPage(pageNumber);
    _currentJuz = QuranPageHelper.getJuzForPage(pageNumber);
    
    // Load coordinates for the new page
    _pageCoordinates = await AyahSyncService().getPageCoordinates(pageNumber);
    
    setState(() => _isLoading = false);
  }

  void _toggleFullscreen() {
    setState(() => _showBars = !_showBars);
    if (_showBars) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
                      icon: Icons.swap_horiz_rounded,
                      label: _currentReading == ReadingService.hafs ? 'رواية ورش' : 'رواية حفص',
                      onTap: () async {
                        Navigator.pop(context);
                        final nextReading = _currentReading == ReadingService.hafs 
                            ? ReadingService.warsh 
                            : ReadingService.hafs;
                        await ReadingService.setSelectedReading(nextReading);
                        await _loadPageData(_currentPage);
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
                                style: GoogleFonts.amiri()),
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
              border:
                  Border.all(color: AppColors.emerald.withValues(alpha: 0.1)),
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
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.emerald))
          : GestureDetector(
              onTap: _toggleFullscreen,
              child: Stack(
                children: [
                  // محتوى الصفحات — Page content
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 604,
                      onPageChanged: (index) {
                        final page = index + 1;
                        setState(() {
                          _currentPage = page;
                          _currentSurahName =
                              QuranPageHelper.getSurahNameForPage(page);
                          _currentJuz = QuranPageHelper.getJuzForPage(page);
                          if (_showAudioPlayer) _showAudioPlayer = false;
                        });
                        BookmarkService.saveLastRead(
                          surahNumber: 0,
                          surahName: 'المصحف',
                          pageNumber: page,
                        );
                        StreakService.recordReading();
                        ReadingStatsService.recordSession();
                        KhatmaService.recordPage();
                      },
                      itemBuilder: (context, index) {
                        final pageNumber = index + 1;
                        return InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: GestureDetector(
                            onLongPress: () =>
                                _showPageOptions(context, pageNumber),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(color: Colors.white),
                                _buildPageImage(pageNumber),

                                // Highlight layer
                                if (_currentPage == pageNumber &&
                                    _activeAyah != null)
                                  AyahHighlighter(
                                    coordinates: _pageCoordinates
                                        .where((c) =>
                                            c.surahNumber == _activeSurah &&
                                            c.ayahNumber == _activeAyah)
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // الشريط العلوي — Top Bar
                  if (_showBars)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildTopBar(),
                    ),

                  // شريط المعلومات السفلي — Bottom Bar
                  if (_showBars)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomBar(),
                    ),

                  // مشغل الصوت — Audio Player
                  if (_showAudioPlayer)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: MushafAudioPlayer(
                        pageNumber: _currentPage,
                        onAyahChanged: (surah, ayah) {
                          setState(() {
                            _activeSurah = surah;
                            _activeAyah = ayah;
                          });
                        },
                        onClose: () {
                          setState(() {
                            _showAudioPlayer = false;
                            _activeAyah = null;
                            _activeSurah = null;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildPageImage(int pageNumber) {
    if (pageNumber <= 5) {
      return Image.asset(
        'assets/mushaf/page${pageNumber.toString().padLeft(3, '0')}.png',
        fit: BoxFit.fill,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(pageNumber),
      );
    } else if (_isDownloaded && _mushafDirPath != null) {
      final file = File(
          '$_mushafDirPath/page${pageNumber.toString().padLeft(3, '0')}.png');
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(pageNumber),
        );
      }
    }
    return _buildPlaceholder(pageNumber);
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 5,
          bottom: 8,
          left: 10,
          right: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.emerald.withValues(alpha: 0.9),
            AppColors.emerald.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentSurahName,
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'الجزء $_currentJuz',
                style: GoogleFonts.amiri(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () => _showPageOptions(context, _currentPage),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'صفحة $_currentPage',
            style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          Text(
            'اسحب لليمين واليسار للتنقل',
            style: GoogleFonts.amiri(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: AppColors.gold),
            onPressed: () async {
              await BookmarkService.addPageBookmark(pageNumber: _currentPage);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('تم الحفظ', style: GoogleFonts.amiri())),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(int pageNumber) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded,
                size: 100, color: AppColors.emerald),
            const SizedBox(height: 20),
            Text(
              'صفحة $pageNumber',
              style: GoogleFonts.amiri(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.emerald),
            ),
            const SizedBox(height: 10),
            Text(
              'الآن في وضع المعاينة\nحمّل الصفحات لقراءة المصحف كاملاً',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
