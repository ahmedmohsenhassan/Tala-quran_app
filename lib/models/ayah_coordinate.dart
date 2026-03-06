class AyahCoordinate {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;

  AyahCoordinate({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  // Example factory for SQLite mapping
  factory AyahCoordinate.fromMap(Map<String, dynamic> map) {
    return AyahCoordinate(
      surahNumber: map['sura_number'],
      ayahNumber: map['ayah_number'],
      pageNumber: map['page_number'],
      minX: map['min_x'],
      maxX: map['max_x'],
      minY: map['min_y'],
      maxY: map['max_y'],
    );
  }
}
