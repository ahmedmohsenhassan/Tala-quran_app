import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

class HifzDatabaseService {
  static final HifzDatabaseService _instance = HifzDatabaseService._internal();
  factory HifzDatabaseService() => _instance;
  HifzDatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'hifz_heatmap.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hifz_scores(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah INTEGER NOT NULL,
            ayah INTEGER NOT NULL,
            score REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            UNIQUE(surah, ayah)
          )
        ''');
      },
    );
  }

  /// يحفظ أو يُحدث درجة حفظ المستخدم لآية معينة
  Future<void> saveTestResult(int surah, int ayah, double score) async {
    try {
      final db = await database;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await db.insert(
        'hifz_scores',
        {
          'surah': surah,
          'ayah': ayah,
          'score': score,
          'timestamp': timestamp,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 Hifz Score Saved: Surah $surah, Ayah $ayah -> ${(score * 100).toInt()}%');
    } catch (e) {
      debugPrint('❌ Error saving Hifz result: $e');
    }
  }

  /// يحصل على الخريطة الحرارية لسورة كاملة (قائمة بنسبة حفظ كل آية)
  Future<Map<int, double>> getSurahHeatmap(int surah) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'hifz_scores',
        where: 'surah = ?',
        whereArgs: [surah],
      );

      Map<int, double> heatmap = {};
      for (var map in maps) {
        heatmap[map['ayah'] as int] = map['score'] as double;
      }
      return heatmap;
    } catch (e) {
      debugPrint('❌ Error fetching Hifz heatmap: $e');
      return {};
    }
  }

  /// إحصائيات عامة عن مدى قوة الحفظ
  Future<double> getGlobalHifzAverage() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT AVG(score) as avg_score FROM hifz_scores');
      if (result.isNotEmpty && result.first['avg_score'] != null) {
        return result.first['avg_score'] as double;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}
