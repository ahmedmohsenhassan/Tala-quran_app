// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// سكريبت الأداة المساعدة (Utilities)
/// لتحميل أول 5 صفحات (عينة المطور) ووضعها في مجلد assets/mushaf محلياً على الكمبيوتر
/// تم إضافة معالجة Redirects الخاصة بموقع Github
void main() {
  test('تحميل العينة', () async {
    print('جاري تهيئة مجلد assets/mushaf على جهاز الكمبيوتر...');
    final dir = Directory('assets/mushaf');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final client = HttpClient();
    const baseUrl = 'https://everyayah.com/data/quran_images_android/page';

    print('جاري تهيئة الاتصال وتنزيل العينة...');

    for (int i = 1; i <= 5; i++) {
      final pageStr = i.toString().padLeft(3, '0');
      final fileName = 'page$pageStr.png';
      final file = File('${dir.path}/$fileName');

      print('جاري تحميل $fileName...');
      try {
        final request = await client.getUrl(Uri.parse('$baseUrl$pageStr.png'));
        request.followRedirects = true;

        final response = await request.close();
        if (response.statusCode == 200) {
          await response.pipe(file.openWrite());
          print(
              '[ نجاح ] تم تحميل $fileName بنجاح. الحجم: ${file.lengthSync()}');
        } else {
          print('[ فشل ] الكود ليس 200: ${response.statusCode}');
        }
      } catch (e) {
        print('[ خطأ ] فشل في تحميل $fileName: $e');
      }
    }
  });
}
