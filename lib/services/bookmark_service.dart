import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة العلامات المرجعية
/// Bookmark service for saving reading progress
class BookmarkService {
  static const String _bookmarksKey = 'bookmarks';
  static const String _lastReadKey = 'last_read';

  /// حفظ علامة مرجعية
  /// Save a bookmark
  static Future<void> addBookmark({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    final bookmark = {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // تجنب التكرار - Avoid duplicates
    bookmarks.removeWhere((b) =>
        b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber);
    bookmarks.insert(0, bookmark);

    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  /// حذف علامة مرجعية
  /// Remove a bookmark
  static Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();

    bookmarks.removeWhere((b) =>
        b['surahNumber'] == surahNumber && b['ayahNumber'] == ayahNumber);

    await prefs.setString(_bookmarksKey, json.encode(bookmarks));
  }

  /// الحصول على كل العلامات المرجعية
  /// Get all bookmarks
  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_bookmarksKey);
    if (data == null) return [];
    final List<dynamic> decoded = json.decode(data);
    return decoded.cast<Map<String, dynamic>>();
  }

  /// حفظ آخر موضع قراءة
  /// Save last read position
  static Future<void> saveLastRead({
    required int surahNumber,
    required String surahName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _lastReadKey,
        json.encode({
          'surahNumber': surahNumber,
          'surahName': surahName,
          'timestamp': DateTime.now().toIso8601String(),
        }));
  }

  /// الحصول على آخر موضع قراءة
  /// Get last read position
  static Future<Map<String, dynamic>?> getLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_lastReadKey);
    if (data == null) return null;
    return json.decode(data);
  }
}
