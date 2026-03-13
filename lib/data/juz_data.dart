/// بيانات الأجزاء والأحزاب — Juz & Hizb Data
/// كل جزء يبدأ من صفحة معينة ويحتوي على حزبين (كل حزب = ربعين)
library;

class JuzInfo {
  final int number;
  final int startPage;
  final String startSurah;
  final int startAyah;

  const JuzInfo({
    required this.number,
    required this.startPage,
    required this.startSurah,
    required this.startAyah,
  });
}

class JuzData {
  /// بيانات الأجزاء الثلاثين
  static const List<JuzInfo> juzList = [
    JuzInfo(number: 1, startPage: 1, startSurah: 'الفاتحة', startAyah: 1),
    JuzInfo(number: 2, startPage: 22, startSurah: 'البقرة', startAyah: 142),
    JuzInfo(number: 3, startPage: 42, startSurah: 'البقرة', startAyah: 253),
    JuzInfo(number: 4, startPage: 62, startSurah: 'آل عمران', startAyah: 93),
    JuzInfo(number: 5, startPage: 82, startSurah: 'النساء', startAyah: 24),
    JuzInfo(number: 6, startPage: 102, startSurah: 'النساء', startAyah: 148),
    JuzInfo(number: 7, startPage: 122, startSurah: 'المائدة', startAyah: 82),
    JuzInfo(number: 8, startPage: 142, startSurah: 'الأنعام', startAyah: 111),
    JuzInfo(number: 9, startPage: 162, startSurah: 'الأعراف', startAyah: 88),
    JuzInfo(number: 10, startPage: 182, startSurah: 'الأنفال', startAyah: 41),
    JuzInfo(number: 11, startPage: 202, startSurah: 'التوبة', startAyah: 93),
    JuzInfo(number: 12, startPage: 222, startSurah: 'هود', startAyah: 6),
    JuzInfo(number: 13, startPage: 242, startSurah: 'يوسف', startAyah: 53),
    JuzInfo(number: 14, startPage: 262, startSurah: 'الحجر', startAyah: 1),
    JuzInfo(number: 15, startPage: 282, startSurah: 'الإسراء', startAyah: 1),
    JuzInfo(number: 16, startPage: 302, startSurah: 'الكهف', startAyah: 75),
    JuzInfo(number: 17, startPage: 322, startSurah: 'الأنبياء', startAyah: 1),
    JuzInfo(number: 18, startPage: 342, startSurah: 'المؤمنون', startAyah: 1),
    JuzInfo(number: 19, startPage: 362, startSurah: 'الفرقان', startAyah: 21),
    JuzInfo(number: 20, startPage: 382, startSurah: 'النمل', startAyah: 56),
    JuzInfo(number: 21, startPage: 402, startSurah: 'العنكبوت', startAyah: 46),
    JuzInfo(number: 22, startPage: 422, startSurah: 'الأحزاب', startAyah: 31),
    JuzInfo(number: 23, startPage: 442, startSurah: 'يس', startAyah: 28),
    JuzInfo(number: 24, startPage: 462, startSurah: 'الزمر', startAyah: 32),
    JuzInfo(number: 25, startPage: 482, startSurah: 'فصلت', startAyah: 47),
    JuzInfo(number: 26, startPage: 502, startSurah: 'الأحقاف', startAyah: 1),
    JuzInfo(number: 27, startPage: 522, startSurah: 'الذاريات', startAyah: 31),
    JuzInfo(number: 28, startPage: 542, startSurah: 'المجادلة', startAyah: 1),
    JuzInfo(number: 29, startPage: 562, startSurah: 'الملك', startAyah: 1),
    JuzInfo(number: 30, startPage: 582, startSurah: 'النبأ', startAyah: 1),
  ];

  /// أسماء الأجزاء الشائعة
  static const List<String> juzNames = [
    'آلم',
    'سيقول',
    'تلك الرسل',
    'لن تنالوا',
    'والمحصنات',
    'لا يحب الله',
    'وإذا سمعوا',
    'ولو أننا',
    'قال الملأ',
    'واعلموا',
    'يعتذرون',
    'وما من دابة',
    'وما أبرئ',
    'ربما',
    'سبحان الذي',
    'قال ألم',
    'اقترب للناس',
    'قد أفلح',
    'وقال الذين',
    'أمن خلق',
    'اتل ما أوحي',
    'ومن يقنت',
    'وما لي',
    'فمن أظلم',
    'إليه يرد',
    'حم',
    'قال فما خطبكم',
    'قد سمع الله',
    'تبارك الذي',
    'عم يتساءلون',
  ];

  /// الحصول على اسم الجزء من رقمه
  static String getJuzName(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) return '';
    return juzNames[juzNumber - 1];
  }

  /// الحصول على الصفحة الأولى للجزء
  static int getStartPage(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) return 1;
    return juzList[juzNumber - 1].startPage;
  }
}
