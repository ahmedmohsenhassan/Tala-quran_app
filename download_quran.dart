import 'dart:io';

void main() async {
  // ignore: avoid_print
  print('Starting download of verified Quran JSON...');
  final url = Uri.parse('https://raw.githubusercontent.com/risan/quran-json/master/dist/quran.json');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  
  if (response.statusCode == 200) {
    final file = File('assets/data/quran.json');
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await response.pipe(file.openWrite());
    // ignore: avoid_print
    print('✅ Download complete! Saved to assets/data/quran.json');
  } else {
    // ignore: avoid_print
    print('❌ Failed to download with status code: ${response.statusCode}');
  }
}
