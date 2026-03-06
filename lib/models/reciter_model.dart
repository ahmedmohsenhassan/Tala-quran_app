/// مودل القارئ
/// Reciter model
class Reciter {
  final String id;
  final String name;
  final String subTitle;
  final String imageUrl;
  final String baseUrl; // Base URL for audio files

  const Reciter({
    required this.id,
    required this.name,
    required this.subTitle,
    required this.imageUrl,
    required this.baseUrl,
  });

  // قائمة القراء الافتراضية - Default reciters list
  static List<Reciter> get defaultReciters => [
        const Reciter(
          id: 'al_afasy',
          name: 'مشاري راشد العفاسي',
          subTitle: 'جودة متوسطة - AlAfasy',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/1/mishary-rashid-alafasy.png',
          baseUrl: 'https://everyayah.com/data/Mishary_Rashid_Alafasy_128kbps/',
        ),
        const Reciter(
          id: 'al_husary',
          name: 'محمود خليل الحصري',
          subTitle: 'مرتل - AlHusary',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/2/mahmoud-khalil-al-hussary.png',
          baseUrl: 'https://everyayah.com/data/Husary_128kbps/',
        ),
        const Reciter(
          id: 'al_minshawi',
          name: 'محمد صديق المنشاوي',
          subTitle: 'مرتل - Al-Minshawi',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/3/muhammad-siddiq-al-minshawi.png',
          baseUrl: 'https://everyayah.com/data/Minshawi_Murattal_128kbps/',
        ),
        const Reciter(
          id: 'al_ghamdi',
          name: 'سعد الغامدي',
          subTitle: 'Saad Al-Ghamdi',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/4/saad-al-ghamdi.png',
          baseUrl: 'https://everyayah.com/data/Ghamadi_40kbps/',
        ),
      ];
}
