import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// 🗄️ خدمة قاعدة بيانات البحث المتقدم للمصحف
/// Ultra-fast offline SQLite Search Engine for the Quran
class SearchDatabaseService {
  static final SearchDatabaseService _instance = SearchDatabaseService._internal();
  factory SearchDatabaseService() => _instance;
  SearchDatabaseService._internal();

  static Database? _database;
  bool _isInitializing = false;

  /// تهيئة قاعدة البيانات
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // إذا كان يتم التجهيز حالياً، انتظر (يمنع تعدد العمليات المتوازية لنفس المهمة)
    int retries = 0;
    while (_isInitializing && retries < 20) {
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }
    
    if (_database != null) return _database!;
    
    _isInitializing = true;
    _database = await _initDB('quran_search.db');
    await _checkAndPopulateData(_database!);
    _isInitializing = false;
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ayahs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        text_uthmani TEXT NOT NULL,
        text_clean TEXT NOT NULL,
        verse_key TEXT NOT NULL
      )
    ''');

    // Index for blazing fast search
    await db.execute('CREATE INDEX idx_text_clean ON ayahs (text_clean)');
  }

  /// إزالة التشكيل وكل الرموز الزائدة من النص العربي لتمكين البحث المرن
  String removeTashkeel(String text) {
    // إزالة التشكيل وعلامات الوقف، استبدال الألف بكل أشكالها بألف عادية، وغيرها
    String clean = text.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u08D4-\u08E2\u08F0-\u08FE]'), '');
    clean = clean.replaceAll(RegExp(r'[أإآا]'), 'ا'); // توحيد جميع أشكال حرف الألف
    clean = clean.replaceAll('ى', 'ي'); // توحيد الألف المقصورة مع الياء
    clean = clean.replaceAll('ة', 'ه'); // تاء مربوطة قريبة من الهاء لبعض نتائج البحث
    clean = clean.replaceAll('ؤ', 'و');
    clean = clean.replaceAll('ئ', 'ي');
    return clean;
  }

  /// التحقق مما إذا كانت قاعدة البيانات فارغة وتعبئتها إذا لزم الأمر
  Future<void> _checkAndPopulateData(Database db) async {
    final count = await Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ayahs'));
    
    // إجمالي عدد الآيات في القرآن هو 6236
    if (count != null && count >= 6236) {
      return; // البيانات موجودة مسبقاً
    }

    debugPrint('⏳ [SearchDatabaseService] Populating Quran Search SQLite from JSON Assets...');

    // مسح أي بيانات سابقة مجزأة
    await db.execute('DELETE FROM ayahs');

    // استخدام Batch لتسريع عملية الإدراج بشكل هائل
    Batch batch = db.batch();

    try {
      for (int surahNum = 1; surahNum <= 114; surahNum++) {
        final String jsonStr = await rootBundle.loadString('assets/surahs/surah_$surahNum.json');
        final Map<String, dynamic> surahData = json.decode(jsonStr);
        final List verses = surahData['verses'];

        for (var v in verses) {
          final String verseKey = v['verse_key'];
          final String textUthmani = v['text_uthmani'];
          final int ayahNum = int.parse(verseKey.split(':')[1]);

          batch.insert('ayahs', {
            'surah': surahNum,
            'ayah': ayahNum,
            'text_uthmani': textUthmani,
            'text_clean': removeTashkeel(textUthmani),
            'verse_key': verseKey,
          });
        }
      }
      
      await batch.commit(noResult: true); // التزام بالعمليات دفعة واحدة
      debugPrint('✅ [SearchDatabaseService] Quran Search SQLite Population Complete! (6236 Ayahs inserted)');
    } catch (e) {
      debugPrint('❌ [SearchDatabaseService] Error populating DB: $e');
    }
  }

  /// البحث عن النص في قاعدة البيانات
  Future<List<Map<String, dynamic>>> search(String query) async {
    final cleanQuery = removeTashkeel(query.trim());
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return []; // تجنب الاستعلام المكلف لحرف واحد

    final db = await database;
    
    // البحث بالاعتماد على الكلمة المجردة (يسمح بالبحث الجزئي أو الكلي)
    final results = await db.query(
      'ayahs',
      columns: ['surah', 'ayah', 'text_uthmani', 'verse_key'],
      where: 'text_clean LIKE ?',
      whereArgs: ['%$cleanQuery%'],
      limit: 100, // إرجاع أول 100 نتيجة فقط للحفاظ على استقرار الواجهة
    );

    return results.map((r) => {
      'surahNumber': r['surah'].toString(),
      'verseNumber': r['ayah'].toString(),
      'text': r['text_uthmani'],
      'verseKey': r['verse_key'],
    }).toList();
  }
}
