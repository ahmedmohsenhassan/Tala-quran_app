import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../services/bookmark_service.dart';
import '../../utils/quran_page_helper.dart';
import '../../screens/mushaf_viewer_screen.dart';

/// ❤️ مكون محتوى مفضلات المستخدم في الصفحة الرئيسية
class FavoritesTabContent extends StatefulWidget {
  const FavoritesTabContent({super.key});

  @override
  State<FavoritesTabContent> createState() => _FavoritesTabContentState();
}

class _FavoritesTabContentState extends State<FavoritesTabContent> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkService.getBookmarks();
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border_rounded,
                color: AppColors.gold.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            Text(
              'لا توجد مفضلات بعد',
              style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'احفظ الآيات التي تحبها للرجوع إليها هنا',
              style:
                  GoogleFonts.amiri(color: AppColors.textMuted.withValues(alpha: 0.6), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = _bookmarks[index];
        return _buildFavoriteTile(bookmark);
      },
    );
  }

  Widget _buildFavoriteTile(Map<String, dynamic> bookmark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bookmark_rounded, color: AppColors.gold, size: 20),
        ),
        title: Text(
          bookmark['surahName'] ?? '',
          style: GoogleFonts.amiri(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'الآية ${bookmark['ayahNumber']}',
          style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.gold, size: 14),
        onTap: () {
          final page = QuranPageHelper.getPageForSurah(bookmark['surahNumber']);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MushafViewerScreen(initialPage: page),
            ),
          );
        },
      ),
    );
  }
}
