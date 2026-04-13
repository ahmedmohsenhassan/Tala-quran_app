import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    // ignore: avoid_print
    print("Testing Tafseer...");
    final res1 = await dio.get('https://quranenc.com/api/v1/translation/ayah/arabic_moyassar/1/1');
    // ignore: avoid_print
    print('Tafseer status: ${res1.statusCode}');
    // ignore: avoid_print
    print('Tafseer response: ${res1.data}');
    
    // ignore: avoid_print
    print("\nTesting Translation...");
    final res2 = await dio.get('https://quranenc.com/api/v1/translation/ayah/english_saheeh/1/1');
    // ignore: avoid_print
    print('Translation status: ${res2.statusCode}');
    // ignore: avoid_print
    print('Translation response: ${res2.data}');
  } catch (e) {
    if (e is DioException) {
      // ignore: avoid_print
      print('Error: ${e.response?.statusCode} ${e.response?.data}');
    } else {
      // ignore: avoid_print
      print('Error: $e');
    }
  }
}
