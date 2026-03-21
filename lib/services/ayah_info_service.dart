import 'dart:io';
import 'dart:ui'; // 🚀 Added for Rect
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

/// 🎯 خدمة إحداثيات الآيات — Ayah Info Service
/// مسؤول عن جلب إحداثيات (X, Y) لكل كلمة وآية من قاعدة بيانات SQLite
class AyahInfoService {
  static final AyahInfoService _instance = AyahInfoService._internal();
  factory AyahInfoService() => _instance;
  AyahInfoService._internal();

  Database? _db;
  static const String _dbFileName = 'ayahinfo.db';
  static const String _remoteDbUrl = 'https://raw.githubusercontent.com/quran/quran-android/master/app/src/main/assets/databases/ayahinfo.db';

  /// تهيئة قاعدة البيانات — Initialize/Download DB
  Future<void> initialize() async {
    if (_db != null) return;

    final docDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docDir.path, _dbFileName);
    final dbFile = File(dbPath);

    // 1. تنزيل قاعدة البيانات إذا لم تكن موجودة
    if (!await dbFile.exists()) {
      debugPrint('📡 Downloading ayahinfo.db...');
      try {
        await Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        )).download(_remoteDbUrl, dbPath);
        debugPrint('✅ ayahinfo.db downloaded successfully.');
      } catch (e) {
        debugPrint('❌ Failed to download ayahinfo.db: $e');
        return;
      }
    }

    // 2. فتح قاعدة البيانات
    _db = await openDatabase(dbPath, readOnly: true);
  }

  /// جلب إحداثيات آية معينة في صفحة — Get Bounding Boxes for an Ayah
  Future<List<Rect>> getAyahRects(int page, int surah, int ayah) async {
    if (_db == null) await initialize();
    if (_db == null) return [];

    try {
      // الاستعلام عن المربعات المحيطة (Bounding Boxes) للآية
      // ملاحظة: أسماء الجداول والأعمدة قد تختلف حسب نسخة الـ DB (عادة glyphs أو ayah_info)
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
