import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة العلامات المرجعية
/// Bookmark service for saving reading progress
class BookmarkService {
  static const String _bookmarksKey = 'bookmarks';
  static const String _pageBookmarksKey = 'page_bookmarks';
  static const String _lastReadKey = 'last_read';

  /// حفظ علامة مرجعية لآية مع ملاحظة اختيارية
  /// Save a bookmark for an Ayah with an optional note
  static Future<void> addBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
    String? note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    final bookmark = {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'note': note ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // تجنب التكرار - Avoid duplicates
    bookmarks.removeWhere((b) =>
        b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber);
    bookmarks.insert(0, bookmark);

    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  /// تحديث الملاحظة على علامة مرجعية موجودة
  /// Update a note on an existing bookmark
  static Future<void> updateBookmarkNote({
    required int surahNumber,
    required int ayahNumber,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    for (var b in bookmarks) {
      if (b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber) {
        b['note'] = note;
        break;
      }
    }

    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  /// حذف علامة مرجعية لآية
  /// Remove a bookmark for an Ayah
  static Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    bookmarks.removeWhere((b) =>
        b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber);

    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  /// الحصول على كل علامات الآيات
  /// Get all Ayah bookmarks
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_bookmarksKey);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// حفظ علامة مرجعية لصفحة
  /// Save a bookmark for a Page
  static Future<void> addPageBookmark({
    required int pageNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getPageBookmarks();

    final bookmark = {
      'pageNumber': pageNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // تجنب التكرار - Avoid duplicates
    bookmarks.removeWhere((b) => b['pageNumber'] == pageNumber);
    bookmarks.insert(0, bookmark);

    await prefs.setString(_pageBookmarksKey, json.encode(bookmarks));
  }

  /// حذف علامة مرجعية لصفحة
  /// Remove a bookmark for a Page
  static Future<void> removePageBookmark(int pageNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getPageBookmarks();

    bookmarks.removeWhere((b) => b['pageNumber'] == pageNumber);

    await prefs.setString(_pageBookmarksKey, json.encode(bookmarks));
  }

  /// الحصول على كل علامات الصفحات
  /// Get all Page bookmarks
  static Future<List<Map<String, dynamic>>> getPageBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_pageBookmarksKey);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// حفظ آخر موضع قراءة
  /// Save last read position
  static Future<void> saveLastRead({
    required int surahNumber,
    required String surahName,
    int? pageNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastReadKey,
        json.encode({
          'surahNumber': surahNumber,
          'surahName': surahName,
          'pageNumber': pageNumber,
          'timestamp': DateTime.now().toIso8601String(),
        }));
  }

  /// الحصول على آخر موضع قراءة
  /// Get last read position
  static Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastReadKey);
    if (data == null) return null;
    try {
      return json.decode(data);
    } catch (_) {
      return null;
    }
  }
}
