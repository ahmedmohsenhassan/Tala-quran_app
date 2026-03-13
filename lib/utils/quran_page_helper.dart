/// خريطة لربط كل سورة بأول صفحة تبدأ منها في مصحف المدينة
/// Map connecting each Surah to its starting page in Madinah Mushaf
class QuranPageHelper {
  static const Map<int, int> surahStartPage = {
    1: 1,
    2: 2,
    3: 50,
    4: 77,
    5: 106,
    6: 128,
    7: 151,
    8: 177,
    9: 187,
    10: 208,
    11: 221,
    12: 235,
    13: 249,
    14: 255,
    15: 262,
    16: 267,
    17: 282,
    18: 293,
    19: 305,
    20: 312,
    21: 322,
    22: 332,
    23: 342,
    24: 350,
    25: 359,
    26: 367,
    27: 377,
    28: 385,
    29: 396,
    30: 404,
    31: 411,
    32: 415,
    33: 418,
    34: 428,
    35: 434,
    36: 440,
    37: 446,
    38: 453,
    39: 458,
    40: 467,
    41: 477,
    42: 483,
    43: 489,
    44: 496,
    45: 499,
    46: 502,
    47: 507,
    48: 511,
    49: 515,
    50: 518,
    51: 520,
    52: 523,
    53: 526,
    54: 528,
    55: 531,
    56: 534,
    57: 537,
    58: 542,
    59: 545,
    60: 549,
    61: 551,
    62: 553,
    63: 554,
    64: 556,
    65: 558,
    66: 560,
    67: 562,
    68: 564,
    69: 566,
    70: 568,
    71: 570,
    72: 572,
    73: 574,
    74: 575,
    75: 577,
    76: 578,
    77: 580,
    78: 582,
    79: 583,
    80: 585,
    81: 586,
    82: 587,
    83: 587,
    84: 589,
    85: 590,
    86: 591,
    87: 591,
    88: 592,
    89: 593,
    90: 594,
    91: 595,
    92: 595,
    93: 596,
    94: 596,
    95: 597,
    96: 597,
    97: 598,
    98: 598,
    99: 599,
    100: 599,
    101: 600,
    102: 600,
    103: 601,
    104: 601,
    105: 601,
    106: 602,
    107: 602,
    108: 602,
    109: 603,
    110: 603,
    111: 603,
    112: 604,
    113: 604,
    114: 604,
  };

  /// الحصول على رقم الصفحة من رقم السورة
  static int getPageForSurah(int surahNumber) {
    return surahStartPage[surahNumber] ?? 1;
  }

  /// الحصول على رقم أول سورة تبدأ في أو توجد في هذه الصفحة
  /// Get the first Surah that exists on this page
  static int getSurahForPage(int pageNumber) {
    int closestSurah = 1;
    for (var entry in surahStartPage.entries) {
      if (entry.value <= pageNumber) {
        closestSurah = entry.key;
      } else {
        break;
      }
    }
    return closestSurah;
  }

  /// الحصول على اسم السورة من رقم الصفحة
  static String getSurahNameForPage(int pageNumber) {
    int surahNumber = getSurahForPage(pageNumber);
    return surahNames[surahNumber - 1];
  }

  /// الحصول على رقم الجزء من رقم الصفحة
  static int getJuzForPage(int pageNumber) {
    if (pageNumber >= 582) return 30;
    if (pageNumber >= 562) return 29;
    if (pageNumber >= 542) return 28;
    if (pageNumber >= 522) return 27;
    if (pageNumber >= 502) return 26;
    if (pageNumber >= 482) return 25;
    if (pageNumber >= 462) return 24;
    if (pageNumber >= 442) return 23;
    if (pageNumber >= 422) return 22;
    if (pageNumber >= 402) return 21;
    if (pageNumber >= 382) return 20;
    if (pageNumber >= 362) return 19;
    if (pageNumber >= 342) return 18;
    if (pageNumber >= 322) return 17;
    if (pageNumber >= 302) return 16;
    if (pageNumber >= 282) return 15;
    if (pageNumber >= 262) return 14;
    if (pageNumber >= 242) return 13;
    if (pageNumber >= 222) return 12;
    if (pageNumber >= 202) return 11;
    if (pageNumber >= 182) return 10;
    if (pageNumber >= 162) return 9;
    if (pageNumber >= 142) return 8;
    if (pageNumber >= 122) return 7;
    if (pageNumber >= 102) return 6;
    if (pageNumber >= 82) return 5;
    if (pageNumber >= 62) return 4;
    if (pageNumber >= 42) return 3;
    if (pageNumber >= 22) return 2;
    return 1;
  }

  /// الحصول على رقم أول صفحة للجزء
  static int getPageForJuz(int juzNumber) {
    const juzStartPages = {
      1: 1, 2: 22, 3: 42, 4: 62, 5: 82, 6: 102, 7: 122, 8: 142, 9: 162, 10: 182,
      11: 202, 12: 222, 13: 242, 14: 262, 15: 282, 16: 302, 17: 322, 18: 342, 19: 362, 20: 382,
      21: 402, 22: 422, 23: 442, 24: 462, 25: 482, 26: 502, 27: 522, 28: 542, 29: 562, 30: 582,
    };
    return juzStartPages[juzNumber] ?? 1;
  }

  static const List<String> surahNames = [
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'إبراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبأ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الإنسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الانفطار',
    'المطففين',
    'الانشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس'
  ];
}
