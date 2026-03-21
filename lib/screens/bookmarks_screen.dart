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
  List<Map<String, dynamic>> _pageBookmarks = [];
  Map<String, dynamic>? _lastRead;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookmarks = await BookmarkService.getBookmarks();
    final pageBookmarks = await BookmarkService.getPageBookmarks();
    final lastRead = await BookmarkService.getLastRead();
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _pageBookmarks = pageBookmarks;
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

  Future<void> _removePageBookmark(int index) async {
    final bookmark = _pageBookmarks[index];
    await BookmarkService.removePageBookmark(bookmark['pageNumber']);
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
            'المفضلة والعلامات',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 26,
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
          _buildSectionHeader('مُتابعة القراءة', Icons.history_rounded),
          const SizedBox(height: 12),
          _buildBookmarkCard(
            icon: Icons.auto_stories_rounded,
            title: _lastRead!['surahName'] ?? '',
            subtitle: _formatDate(_lastRead!['timestamp']),
            onTap: () {
              final page = _lastRead!['pageNumber'] ??
                  QuranPageHelper.getPageForSurah(_lastRead!['surahNumber']);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MushafViewerScreen(initialPage: page),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],

        // علامات الصفحات - Page bookmarks
        if (_pageBookmarks.isNotEmpty) ...[
          _buildSectionHeader('صفحات المصحف', Icons.menu_book_rounded),
          const SizedBox(height: 12),
          ...List.generate(_pageBookmarks.length, (index) {
            final bookmark = _pageBookmarks[index];
            return Dismissible(
              key: ValueKey('page_${bookmark['pageNumber']}'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _removePageBookmark(index),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildBookmarkCard(
                  icon: Icons.sticky_note_2_rounded,
                  title: 'صفحة ${bookmark['pageNumber']}',
                  subtitle:
                      'المصحف المدينة • ${_formatDate(bookmark['timestamp'])}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MushafViewerScreen(
                            initialPage: bookmark['pageNumber']),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
        ],

        // العلامات المرجعية - Bookmarks list
        _buildSectionHeader('الآيات المحفوظة', Icons.bookmark_rounded),
        const SizedBox(height: 12),

        if (_bookmarks.isEmpty && _pageBookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.bookmark_border,
                      color: AppColors.gold.withValues(alpha: 0.4), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد علامات مرجعية\nاحفظ صفحة أو آية للرجوع إليها لاحقاً',
                    style: GoogleFonts.amiri(
                        color: AppColors.textMuted, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else if (_bookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'لا توجد آيات محفوظة',
                style:
                    GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 16),
              ),
            ),
          )
        else
          ...List.generate(_bookmarks.length, (index) {
            final bookmark = _bookmarks[index];
            final String note = bookmark['note'] ?? '';
            return Dismissible(
              key: ValueKey(
                  '${bookmark['surahNumber']}_${bookmark['ayahNumber']}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 28),
              ),
              onDismissed: (_) => _removeBookmark(index),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSmartBookmarkCard(
                  icon: Icons.bookmark_outline_rounded,
                  title: bookmark['surahName'] ?? '',
                  subtitle:
                      'الآية ${bookmark['ayahNumber']} • ${_formatDate(bookmark['timestamp'])}',
                  note: note,
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
                  onNoteTap: () => _showNoteEditor(
                    surahNumber: bookmark['surahNumber'],
                    ayahNumber: bookmark['ayahNumber'],
                    currentNote: note,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBookmarkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.emerald, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.amiri(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 13,
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
      ),
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

  // ============================================================
  //  SMART BOOKMARK CARD WITH NOTES 📝✨
  // ============================================================
  Widget _buildSmartBookmarkCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String note,
    required VoidCallback onTap,
    required VoidCallback onNoteTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppColors.emerald, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.amiri(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.outfit(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // زر تحرير الملاحظة
                    IconButton(
                      icon: Icon(
                        note.isNotEmpty ? Icons.edit_note_rounded : Icons.note_add_rounded,
                        color: AppColors.gold,
                        size: 22,
                      ),
                      onPressed: onNoteTap,
                      tooltip: note.isNotEmpty ? 'تعديل الخاطرة' : 'إضافة خاطرة',
                    ),
                    const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.gold, size: 14),
                  ],
                ),
                // عرض الملاحظة إن وجدت
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded,
                            color: AppColors.gold.withValues(alpha: 0.5), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note,
                            style: GoogleFonts.amiri(
                              color: AppColors.textPrimary.withValues(alpha: 0.8),
                              fontSize: 14,
                              height: 1.6,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  //  NOTE EDITOR DIALOG 📝✨
  // ============================================================
  void _showNoteEditor({
    required int surahNumber,
    required int ayahNumber,
    required String currentNote,
  }) {
    final controller = TextEditingController(text: currentNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(
                  top: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // المقبض
                  Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // العنوان
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'خاطرة روحانية ✨',
                        style: GoogleFonts.amiri(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // حقل الملاحظة
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    minLines: 3,
                    autofocus: true,
                    style: GoogleFonts.amiri(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.8,
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب خاطرتك أو تأملك هنا...',
                      hintStyle: GoogleFonts.amiri(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // أزرار الحفظ
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await BookmarkService.updateBookmarkNote(
                              surahNumber: surahNumber,
                              ayahNumber: ayahNumber,
                              note: controller.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: Text(
                            'حفظ الخاطرة',
                            style: GoogleFonts.amiri(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      if (currentNote.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () async {
                            await BookmarkService.updateBookmarkNote(
                              surahNumber: surahNumber,
                              ayahNumber: ayahNumber,
                              note: '',
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              _loadData();
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent, size: 24),
                          tooltip: 'حذف الخاطرة',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
