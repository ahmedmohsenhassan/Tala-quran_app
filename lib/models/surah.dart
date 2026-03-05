/// Model class representing a Quran Surah (chapter).
/// موديل يمثل سورة من القرآن.
class Surah {
  final int number;      // Surah number (رقم السورة)
  final String name;     // Surah name (اسم السورة)
  final int ayaCount;    // Number of verses (عدد الآيات)

  Surah({
    required this.number,
    required this.name,
    required this.ayaCount,
  });

  /// Factory to create a Surah from JSON.
  /// إنشاء كائن من بيانات JSON.
  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      ayaCount: json['aya'],
    );
  }
}
