import 'dart:io';

void main() async {
  final fontDir = Directory('assets/fonts');
  if (!await fontDir.exists()) {
    await fontDir.create(recursive: true);
  }

  const url = 'https://raw.githubusercontent.com/nassermsr/quran_app_data/main/fonts/KFGQPC_Uthmanic_Script_HAFS_Regular.ttf';
  final destination = File('assets/fonts/KFGQPC_Uthmanic_Script_HAFS_Regular.ttf');

  // ignore: avoid_print
  print('Downloading from $url...');
  final request = await HttpClient().getUrl(Uri.parse(url));
  final response = await request.close();
  await response.pipe(destination.openWrite());
  // ignore: avoid_print
  print('Successfully downloaded KFGQPC Uthmanic Script HAFS.');
}
