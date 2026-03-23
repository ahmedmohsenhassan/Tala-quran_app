import 'dart:io';
import 'dart:ui'; // 🚀 Added for Rect
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// 🎯 خدمة إحداثيات الآيات — Ayah Info Service
/// مسؤول عن جلب إحداثيات (X, Y) لكل كلمة وآية من قاعدة بيانات SQLite
/// 
/// ⚠️ هذه الخدمة تعمل فقط إذا كان ملف ayahinfo.db موجوداً محلياً مسبقاً.
/// لم يعد يتم تحميله من الإنترنت — 100% Offline Architecture.
/// إذا لم يكن الملف موجوداً، ترجع الدوال بيانات فارغة بدون crash.
class AyahInfoService {
  static final AyahInfoService _instance = AyahInfoService._internal();
  factory AyahInfoService() => _instance;
  AyahInfoService._internal();

  Database? _db;
  static const String _dbFileName = 'ayahinfo.db';

  /// تهيئة قاعدة البيانات — Initialize DB (Local Only)
  Future<void> initialize() async {
    if (_db != null) return;

    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docDir.path, _dbFileName);
    final dbFile = File(dbPath);

    if (await dbFile.exists()) {
      _db = await openDatabase(dbPath, readOnly: true);
      debugPrint('✅ [AyahInfo] Local DB found and opened.');
    } else {
      debugPrint('ℹ️ [AyahInfo] No local ayahinfo.db found. Coordinate features disabled.');
    }
  }

  /// جلب إحداثيات آية معينة في صفحة — Get Bounding Boxes for an Ayah
  Future<List<Rect>> getAyahRects(int page, int surah, int ayah) async {
    if (_db == null) await initialize();
    if (_db == null) return [];

    try {
      final List<Map<String, dynamic>> results = await _db!.query(
        'glyphs',
        where: 'page_number = ? AND sura_number = ? AND ayah_number = ?',
        whereArgs: [page, surah, ayah],
      );

      return results.map((row) {
        return Rect.fromLTRB(
          (row['min_x'] as num).toDouble(),
          (row['min_y'] as num).toDouble(),
          (row['max_x'] as num).toDouble(),
          (row['max_y'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error querying ayah rects: $e');
      return [];
    }
  }

  /// جلب إحداثيات كلمة معينة — Get Word Bounding Box
  Future<Rect?> getWordRect(int page, int surah, int ayah, int position) async {
    if (_db == null) await initialize();
    if (_db == null) return null;

    try {
      final List<Map<String, dynamic>> results = await _db!.query(
        'glyphs',
        where: 'page_number = ? AND sura_number = ? AND ayah_number = ? AND position = ?',
        whereArgs: [page, surah, ayah, position],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final row = results.first;
        return Rect.fromLTRB(
          (row['min_x'] as num).toDouble(),
          (row['min_y'] as num).toDouble(),
          (row['max_x'] as num).toDouble(),
          (row['max_y'] as num).toDouble(),
        );
      }
    } catch (e) {
       debugPrint('❌ Error querying word rect: $e');
    }
    return null;
  }

  /// جلب كافة الآيات في الصفحة مع إحداثياتها — Get All Ayahs on a Page
  Future<Map<String, List<Rect>>> getPageAyahMap(int page) async {
    if (_db == null) await initialize();
    if (_db == null) return {};

    try {
      final List<Map<String, dynamic>> results = await _db!.query(
        'glyphs',
        where: 'page_number = ?',
        whereArgs: [page],
      );

      final Map<String, List<Rect>> ayahMap = {};
      for (var row in results) {
        final key = '${row['sura_number']}:${row['ayah_number']}';
        final rect = Rect.fromLTRB(
          (row['min_x'] as num).toDouble(),
          (row['min_y'] as num).toDouble(),
          (row['max_x'] as num).toDouble(),
          (row['max_y'] as num).toDouble(),
        );
        ayahMap.putIfAbsent(key, () => []).add(rect);
      }
      return ayahMap;
    } catch (e) {
      debugPrint('❌ Error querying page ayah map: $e');
      return {};
    }
  }
}
