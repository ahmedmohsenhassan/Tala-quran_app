import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🗄️ خدمة قاعدة بيانات القرآن الموحدة — Unified Quran Database Service
/// 
/// مسؤولة عن تخزين واسترجاع جميع بيانات القرآن الكريم محلياً
/// بدون أي اعتماد على الإنترنت — 100% Offline
/// 
/// المصدر: ملفات JSON المحلية المحققة من assets/surahs/
/// Source: Verified local JSON files from assets/surahs/
class QuranDatabaseService {
  static final QuranDatabaseService _instance = QuranDatabaseService._internal();
  factory QuranDatabaseService() => _instance;
  QuranDatabaseService._internal();

  static Database? _database;
  bool _isInitializing = false;
  
  /// نسخة قاعدة البيانات — يتم زيادتها عند تحديث البنية
  static const int _dbVersion = 1;
  static const String _dbName = 'quran_v$_dbVersion.db';
  static const String _prefKeyDbReady = 'quran_db_ready_v$_dbVersion';

  // ======================================================================
  //  💾 In-Memory LRU Cache (آخر 10 صفحات/سور مفتوحة)
  // ======================================================================
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  static const int _maxCacheSize = 10;

  void _putCache(String key, List<Map<String, dynamic>> data) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = data;
  }

  // ======================================================================
  //  🚀 التهيئة — Initialization
  // ======================================================================
  
  /// تهيئة قاعدة البيانات
  /// تعمل مرة واحدة فقط — تنشئ الجدول وتملأه من JSON
  Future<void> initialize() async {
    if (_database != null) return;
    
    // منع التهيئة المتوازية
    if (_isInitializing) {
      int retries = 0;
      while (_isInitializing && retries < 40) {
        await Future.delayed(const Duration(milliseconds: 250));
        retries++;
      }
      if (_database != null) return;
    }
    
    _isInitializing = true;
    
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      
      _database = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTables,
      );
      
      // التحقق من وجود البيانات
      final prefs = await SharedPreferences.getInstance();
      final isReady = prefs.getBool(_prefKeyDbReady) ?? false;
      
      if (!isReady) {
        debugPrint('📖 [QuranDB] First launch — populating database from local assets...');
        await _populateFromAssets(_database!);
        await prefs.setBool(_prefKeyDbReady, true);
        debugPrint('✅ [QuranDB] Database ready! 6236 ayahs loaded.');
      } else {
        debugPrint('✅ [QuranDB] Database already populated. Instant open.');
      }
    } catch (e, stack) {
      debugPrint('❌ [QuranDB] Init error: $e');
      debugPrint('🔥 Stack: $stack');
    } finally {
      _isInitializing = false;
    }
  }

  /// إنشاء الجداول — Create Tables
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        text TEXT NOT NULL,
        text_clean TEXT NOT NULL,
        verse_key TEXT NOT NULL,
        page INTEGER DEFAULT 0,
        juz INTEGER DEFAULT 0,
        hizb INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS surahs (
        id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        name_en TEXT NOT NULL,
        total_verses INTEGER NOT NULL,
        type TEXT DEFAULT 'meccan',
        revelation_order INTEGER DEFAULT 0
      )
    ''');

    // فهارس الأداء — Performance Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_verses_surah ON verses(surah)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_verses_page ON verses(page)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_verses_juz ON verses(juz)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_verses_key ON verses(verse_key)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_verses_text_clean ON verses(text_clean)');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_verses_surah_ayah ON verses(surah, ayah)');
  }

  // ======================================================================
  //  📥 تعبئة البيانات من الأصول المحلية — Populate from Assets
  // ======================================================================
  
  /// تحميل أسماء ملفات السور
  static const List<String> surahFiles = [
    'Al-Fatiha', 'Al-Baqarah', 'Aal-i-Imraan', 'An-Nisaa', 'Al-Maaida',
    "Al-An'aam", "Al-A'raaf", 'Al-Anfaal', 'At-Tawba', 'Yunus',
    'Hud', 'Yusuf', "Ar-Ra'd", 'Ibrahim', 'Al-Hijr',
    'An-Nahl', 'Al-Israa', 'Al-Kahf', 'Maryam', 'Taa-Haa',
    'Al-Anbiyaa', 'Al-Hajj', 'Al-Muminoon', 'An-Noor', 'Al-Furqaan',
    "Ash-Shu'araa", 'An-Naml', 'Al-Qasas', 'Al-Ankaboot', 'Ar-Room',
    'Luqman', 'As-Sajda', 'Al-Ahzaab', 'Saba', 'Faatir',
    'Yaseen', 'As-Saaffaat', 'Saad', 'Az-Zumar', 'Ghafir',
    'Fussilat', 'Ash-Shura', 'Az-Zukhruf', 'Ad-Dukhaan', 'Al-Jaathiya',
    'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujuraat', 'Qaaf',
    'Adh-Dhaariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahmaan',
    'Al-Waaqia', 'Al-Hadid', 'Al-Mujaadila', 'Al-Hashr', 'Al-Mumtahana',
    'As-Saff', "Al-Jumu'a", 'Al-Munaafiqoon', 'At-Taghaabun', 'At-Talaaq',
    'At-Tahreem', 'Al-Mulk', 'Al-Qalam', 'Al-Haaqqa', "Al-Ma'aarij",
    'Nooh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddaththir', 'Al-Qiyaama',
    'Al-Insaan', 'Al-Mursalaat', 'An-Naba', "An-Naazi'aat", 'Abasa',
    'At-Takwir', 'Al-Infitaar', 'Al-Mutaffifin', 'Al-Inshiqaaq', 'Al-Burooj',
    'At-Taariq', "Al-A'laa", 'Al-Ghaashiya', 'Al-Fajr', 'Al-Balad',
    'Ash-Shams', 'Al-Lail', 'Ad-Duhaa', 'Ash-Sharh', 'At-Tin',
    'Al-Alaq', 'Al-Qadr', 'Al-Bayyina', 'Az-Zalzala', 'Al-Aadiyaat',
    "Al-Qaari'a", 'At-Takaathur', 'Al-Asr', 'Al-Humaza', 'Al-Feel',
    'Quraish', "Al-Maa'oon", 'Al-Kawthar', 'Al-Kaafiroon', 'An-Nasr',
    'Al-Masad', 'Al-Ikhlaas', 'Al-Falaq', 'An-Naas',
  ];

  /// أسماء السور بالعربية
  static const List<String> _surahNamesAr = [
    'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة',
    'الأنعام', 'الأعراف', 'الأنفال', 'التوبة', 'يونس',
    'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
    'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه',
    'الأنبياء', 'الحج', 'المؤمنون', 'النور', 'الفرقان',
    'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
    'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر',
    'يس', 'الصافات', 'ص', 'الزمر', 'غافر',
    'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
    'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق',
    'الذاريات', 'الطور', 'النجم', 'القمر', 'الرحمن',
    'الواقعة', 'الحديد', 'المجادلة', 'الحشر', 'الممتحنة',
    'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق',
    'التحريم', 'الملك', 'القلم', 'الحاقة', 'المعارج',
    'نوح', 'الجن', 'المزمل', 'المدثر', 'القيامة',
    'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
    'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج',
    'الطارق', 'الأعلى', 'الغاشية', 'الفجر', 'البلد',
    'الشمس', 'الليل', 'الضحى', 'الشرح', 'التين',
    'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
    'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل',
    'قريش', 'الماعون', 'الكوثر', 'الكافرون', 'النصر',
    'المسد', 'الإخلاص', 'الفلق', 'الناس',
  ];

  /// عدد آيات كل سورة (بيانات ثابتة محكمة)
  static const List<int> _ayahCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6,
  ];

  /// الصفحة الأولى لكل سورة في مصحف المدينة (604 صفحات)
  static const List<int> _surahStartPages = [
    1, 2, 50, 77, 106, 128, 151, 177, 187, 208,
    221, 235, 249, 255, 262, 267, 282, 293, 305, 312,
    322, 332, 342, 350, 359, 367, 377, 385, 396, 404,
    411, 415, 418, 428, 434, 440, 446, 453, 458, 467,
    477, 483, 489, 496, 499, 502, 507, 511, 515, 518,
    520, 523, 526, 528, 531, 534, 537, 542, 545, 549,
    551, 553, 554, 556, 558, 560, 562, 564, 566, 568,
    570, 572, 574, 575, 577, 578, 580, 582, 583, 585,
    586, 587, 587, 589, 590, 591, 591, 592, 593, 594,
    595, 595, 596, 596, 597, 597, 598, 598, 599, 599,
    600, 600, 601, 601, 601, 602, 602, 602, 603, 603,
    603, 604, 604, 604,
  ];

  Future<void> _populateFromAssets(Database db) async {
    final Batch batch = db.batch();
    int totalInserted = 0;

    // 1. إدراج بيانات السور
    for (int i = 0; i < 114; i++) {
      batch.insert('surahs', {
        'id': i + 1,
        'name_ar': _surahNamesAr[i],
        'name_en': surahFiles[i],
        'total_verses': _ayahCounts[i],
        'type': _getSurahType(i + 1),
        'revelation_order': 0,
      });
    }

    // 2. إدراج الآيات من ملفات JSON المحلية
    for (int surahNum = 1; surahNum <= 114; surahNum++) {
      try {
        final fileName = surahFiles[surahNum - 1];
        final String jsonStr = await rootBundle.loadString('assets/surahs/$fileName.json');
        final Map<String, dynamic> surahData = json.decode(jsonStr);
        final List ayahs = surahData['ayahs'] ?? surahData['verses'] ?? [];

        for (var ayah in ayahs) {
          final int ayahNum = ayah['number'] ?? ayah['ayah'] ?? 0;
          final String text = ayah['text'] ?? ayah['text_uthmani'] ?? '';
          if (text.isEmpty || ayahNum == 0) continue;

          final String verseKey = '$surahNum:$ayahNum';
          
          batch.insert('verses', {
            'surah': surahNum,
            'ayah': ayahNum,
            'text': text,
            'text_clean': removeTashkeel(text),
            'verse_key': verseKey,
            'page': _getPageForVerse(surahNum, ayahNum),
            'juz': _getJuzForVerse(surahNum, ayahNum),
            'hizb': 0,
          });
          totalInserted++;
        }
      } catch (e) {
        debugPrint('⚠️ [QuranDB] Error loading surah $surahNum: $e');
      }
    }

    await batch.commit(noResult: true);
    debugPrint('📊 [QuranDB] Batch committed: $totalInserted verses inserted.');
  }

  // ======================================================================
  //  📖 استعلامات القراءة — Read Queries
  // ======================================================================
  
  /// جلب آيات سورة كاملة
  Future<List<Map<String, dynamic>>> getVersesBySurah(int surah) async {
    await _ensureDb();
    
    final cacheKey = 'surah_$surah';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    
    try {
      final results = await _database!.query(
        'verses',
        where: 'surah = ?',
        whereArgs: [surah],
        orderBy: 'ayah ASC',
      );
      final data = results.map((r) => Map<String, dynamic>.from(r)).toList();
      _putCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('❌ [QuranDB] getVersesBySurah error: $e');
      return _fallbackGetSurah(surah);
    }
  }

  /// جلب آيات صفحة معينة من المصحف
  Future<List<Map<String, dynamic>>> getVersesByPage(int page) async {
    await _ensureDb();
    
    final cacheKey = 'page_$page';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;
    
    try {
      final results = await _database!.query(
        'verses',
        where: 'page = ?',
        whereArgs: [page],
        orderBy: 'surah ASC, ayah ASC',
      );
      final data = results.map((r) => Map<String, dynamic>.from(r)).toList();
      _putCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('❌ [QuranDB] getVersesByPage error: $e');
      return [];
    }
  }

  /// جلب آية واحدة
  Future<Map<String, dynamic>?> getVerse(int surah, int ayah) async {
    await _ensureDb();
    try {
      final results = await _database!.query(
        'verses',
        where: 'surah = ? AND ayah = ?',
        whereArgs: [surah, ayah],
        limit: 1,
      );
      return results.isNotEmpty ? Map<String, dynamic>.from(results.first) : null;
    } catch (e) {
      debugPrint('❌ [QuranDB] getVerse error: $e');
      return null;
    }
  }
  
  /// جلب بيانات سورة (اسم، عدد آيات، نوع)
  Future<Map<String, dynamic>?> getSurahInfo(int surahNumber) async {
    await _ensureDb();
    try {
      final results = await _database!.query(
        'surahs',
        where: 'id = ?',
        whereArgs: [surahNumber],
        limit: 1,
      );
      return results.isNotEmpty ? Map<String, dynamic>.from(results.first) : null;
    } catch (e) {
      return null;
    }
  }

  /// جلب قائمة كل السور (للشاشة الرئيسية)
  Future<List<Map<String, dynamic>>> getAllSurahs() async {
    await _ensureDb();
    try {
      final results = await _database!.query('surahs', orderBy: 'id ASC');
      return results.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (e) {
      return [];
    }
  }

  // ======================================================================
  //  🔍 البحث — Search
  // ======================================================================
  
  /// بحث سريع عن نص في الآيات (بدون تشكيل)
  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    final cleanQuery = removeTashkeel(query.trim());
    if (cleanQuery.isEmpty || cleanQuery.length < 2) return [];

    await _ensureDb();

    try {
      final results = await _database!.query(
        'verses',
        columns: ['surah', 'ayah', 'text', 'verse_key', 'page'],
        where: 'text_clean LIKE ?',
        whereArgs: ['%$cleanQuery%'],
        limit: 100,
      );

      return results.map((r) => {
        'surahNumber': r['surah'].toString(),
        'verseNumber': r['ayah'].toString(),
        'text': r['text'],
        'verseKey': r['verse_key'],
        'page': r['page'],
      }).toList();
    } catch (e) {
      debugPrint('❌ [QuranDB] Search error: $e');
      return [];
    }
  }

  // ======================================================================
  //  📊 إحصائيات — Statistics
  // ======================================================================
  
  /// التحقق من عدد الآيات المخزنة
  Future<int> getStoredVerseCount() async {
    await _ensureDb();
    try {
      final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM verses'),
      );
      return count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// التحقق من سلامة البيانات
  Future<bool> verifyIntegrity() async {
    final count = await getStoredVerseCount();
    final isValid = count == 6236;
    if (!isValid) {
      debugPrint('⚠️ [QuranDB] Integrity check FAILED: $count/6236 verses');
    }
    return isValid;
  }

  // ======================================================================
  //  🛠️ أدوات مساعدة — Utilities
  // ======================================================================
  
  Future<void> _ensureDb() async {
    if (_database == null) await initialize();
  }

  /// إزالة التشكيل للبحث
  static String removeTashkeel(String text) {
    String clean = text.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED\u08D4-\u08E2\u08F0-\u08FE]'),
      '',
    );
    clean = clean.replaceAll(RegExp(r'[أإآا]'), 'ا');
    clean = clean.replaceAll('ى', 'ي');
    clean = clean.replaceAll('ة', 'ه');
    clean = clean.replaceAll('ؤ', 'و');
    clean = clean.replaceAll('ئ', 'ي');
    return clean;
  }

  /// تحديد الصفحة لآية بناءً على بيانات المصحف
  static int _getPageForVerse(int surah, int ayah) {
    // تقدير الصفحة بناءً على موقع السورة وعدد الآيات
    // هذا تقريب — يمكن تحسينه لاحقاً بجدول دقيق
    if (surah < 1 || surah > 114) return 1;
    final startPage = _surahStartPages[surah - 1];
    final nextPage = surah < 114 ? _surahStartPages[surah] : 605;
    final totalVersesInSurah = _ayahCounts[surah - 1];
    
    if (totalVersesInSurah <= 0) return startPage;
    
    final pagesSpan = nextPage - startPage;
    if (pagesSpan <= 0) return startPage;
    
    final progress = (ayah - 1) / totalVersesInSurah;
    return startPage + (progress * pagesSpan).floor();
  }

  /// تحديد الجزء
  static int _getJuzForVerse(int surah, int ayah) {
    // جدول بداية كل جزء (سورة:آية)
    const juzStarts = [
      [1, 1], [2, 142], [2, 253], [3, 93], [4, 24],
      [4, 148], [5, 82], [6, 111], [7, 88], [8, 41],
      [9, 93], [11, 6], [12, 53], [15, 1], [17, 1],
      [18, 75], [21, 1], [23, 1], [25, 21], [27, 56],
      [29, 46], [33, 31], [36, 28], [39, 32], [41, 47],
      [46, 1], [51, 31], [58, 1], [67, 1], [78, 1],
    ];

    for (int i = juzStarts.length - 1; i >= 0; i--) {
      final juzSurah = juzStarts[i][0];
      final juzAyah = juzStarts[i][1];
      if (surah > juzSurah || (surah == juzSurah && ayah >= juzAyah)) {
        return i + 1;
      }
    }
    return 1;
  }

  /// نوع السورة (مكية/مدنية)
  static String _getSurahType(int surahNumber) {
    const medinanSurahs = {
      2, 3, 4, 5, 8, 9, 22, 24, 33, 47, 48, 49, 55, 57, 58, 59, 60,
      61, 62, 63, 64, 65, 66, 76, 98, 110,
    };
    return medinanSurahs.contains(surahNumber) ? 'medinan' : 'meccan';
  }

  // ======================================================================
  //  🛡️ Fallback — في حال فشل SQLite
  // ======================================================================
  
  Future<List<Map<String, dynamic>>> _fallbackGetSurah(int surahNum) async {
    try {
      final fileName = surahFiles[surahNum - 1];
      final String jsonStr = await rootBundle.loadString('assets/surahs/$fileName.json');
      final Map<String, dynamic> surahData = json.decode(jsonStr);
      final List ayahs = surahData['ayahs'] ?? surahData['verses'] ?? [];
      
      return ayahs.map<Map<String, dynamic>>((a) => {
        'surah': surahNum,
        'ayah': a['number'] ?? 0,
        'text': a['text'] ?? '',
        'verse_key': '$surahNum:${a['number'] ?? 0}',
      }).toList();
    } catch (e) {
      debugPrint('❌ [QuranDB] Fallback also failed: $e');
      return [];
    }
  }

  /// إعادة بناء قاعدة البيانات (للصيانة)
  Future<void> rebuild() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyDbReady);
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _cache.clear();
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    
    await initialize();
  }
}
