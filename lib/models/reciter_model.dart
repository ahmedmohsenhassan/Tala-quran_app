/// مودل القارئ
/// Reciter model
class Reciter {
  final String id;
  final String name;
  final String subTitle;
  final String imageUrl;
  final String baseUrl; // Base URL for everyayah.com (verse-by-verse)
  final String identifier; // Identifier for islamic.network
  final String serverUrl; // Base URL for full surahs (e.g. mp3quran.net)

  const Reciter({
    required this.id,
    required this.name,
    required this.subTitle,
    required this.imageUrl,
    required this.baseUrl,
    required this.identifier,
    required this.serverUrl,
  });

  // قائمة القراء الافتراضية - Default reciters list
  static List<Reciter> get defaultReciters => [
        const Reciter(
          id: 'al_afasy',
          name: 'مشاري راشد العفاسي',
          subTitle: 'AlAfasy',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/6/mishary-rashid-alafasy-profile.jpeg',
          baseUrl: 'https://everyayah.com/data/Mishary_Rashid_Alafasy_128kbps/',
          identifier: 'ar.alafasy',
          serverUrl: 'https://server8.mp3quran.net/afs/',
        ),
        const Reciter(
          id: 'al_husary',
          name: 'محمود خليل الحصري',
          subTitle: 'AlHusary',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/5/mahmoud-khalil-al-hussary-profile.png',
          baseUrl: 'https://everyayah.com/data/Husary_128kbps/',
          identifier: 'ar.husary',
          serverUrl: 'https://server13.mp3quran.net/husr/',
        ),
        const Reciter(
          id: 'al_minshawi',
          name: 'محمد صديق المنشاوي',
          subTitle: 'Al-Minshawi',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/7/mohamed-siddiq-el-minshawi-profile.jpeg',
          baseUrl: 'https://everyayah.com/data/Minshawi_Murattal_128kbps/',
          identifier: 'ar.minshawi',
          serverUrl: 'https://server10.mp3quran.net/minsh/',
        ),
        const Reciter(
          id: 'al_ghamdi',
          name: 'سعد الغامدي',
          subTitle: 'Saad Al-Ghamdi',
          imageUrl:
              'https://static.qurancdn.com/images/reciters/16/saad-al-ghamdi-profile.png?v=1',
          baseUrl: 'https://everyayah.com/data/Ghamadi_40kbps/',
          identifier: 'ar.ghamadi',
          serverUrl: 'https://server7.mp3quran.net/s_gmd/',
        ),
      ];
}
