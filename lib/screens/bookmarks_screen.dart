import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/bookmark_service.dart';
import '../utils/quran_page_helper.dart';
import 'mushaf_viewer_screen.dart';

/// شاشة العلامات المرجعية
/// Bookmarks screen
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  Map<String, dynamic>? _lastRead;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookmarks = await BookmarkService.getBookmarks();
    final lastRead = await BookmarkService.getLastRead();
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _lastRead = lastRead;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(int index) async {
    final bookmark = _bookmarks[index];
    await BookmarkService.removeBookmark(
      bookmark['surahNumber'],
      bookmark['ayahNumber'],
    );
    _loadData();
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
            'العلامات المرجعية',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // آخر قراءة - Last read
        if (_lastRead != null) ...[
          Text(
            'مُتابعة القراءة',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.history, color: AppColors.gold),
              title: Text(
                _lastRead!['surahName'] ?? '',
                style: GoogleFonts.amiri(
                    color: AppColors.textPrimary, fontSize: 18),
              ),
              subtitle: Text(
                _formatDate(_lastRead!['timestamp']),
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_back_ios,
                  color: AppColors.gold, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MushafViewerScreen(
                      initialPage: QuranPageHelper.getPageForSurah(
                          _lastRead!['surahNumber']),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // العلامات المرجعية - Bookmarks list
        Text(
          'العلامات المحفوظة',
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        if (_bookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.bookmark_border,
                      color: AppColors.gold.withValues(alpha: 0.4), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد علامات مرجعية\nاضغط مطولاً على أي آية لحفظها',
                    style: GoogleFonts.amiri(
                        color: AppColors.textMuted, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_bookmarks.length, (index) {
            final bookmark = _bookmarks[index];
            return Dismissible(
              key: ValueKey(
                  '${bookmark['surahNumber']}_${bookmark['ayahNumber']}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.red),
              ),
              onDismissed: (_) => _removeBookmark(index),
              child: Card(
                color: AppColors.cardBackground,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.bookmark, color: AppColors.gold),
                  title: Text(
                    bookmark['surahName'] ?? '',
                    style: GoogleFonts.amiri(
                        color: AppColors.textPrimary, fontSize: 18),
                  ),
                  subtitle: Text(
                    'الآية ${bookmark['ayahNumber']}',
                    style: GoogleFonts.amiri(
                        color: AppColors.textMuted, fontSize: 14),
                  ),
                  trailing: Text(
                    _formatDate(bookmark['timestamp']),
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MushafViewerScreen(
                          initialPage: QuranPageHelper.getPageForSurah(
                              bookmark['surahNumber']),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
