import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// سكريبت الأداة المساعدة (Utilities)
/// لتحميل أول 5 صفحات (عينة المطور) ووضعها في مجلد assets/mushaf محلياً على الكمبيوتر
/// تم وضعه في مجلد test لكي يعمل على (ويندوز) وليس على (المحاكي) لتجنب أخطاء حماية النظام.
void main() {
  test('تحميل الصفحات الخمس الأولى لتعمل بدون إنترنت', () async {
    print('جاري تهيئة مجلد assets/mushaf على جهاز الكمبيوتر...');
    final dir = Directory('assets/mushaf');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final client = HttpClient();
    const baseUrl =
        'https://raw.githubusercontent.com/quran/quran.com-images/master/width_1024/page';

    print('جاري تهيئة الاتصال وتنزيل العينة...');

    for (int i = 1; i <= 5; i++) {
      final pageStr = i.toString().padLeft(3, '0');
      final fileName = 'page$pageStr.png';
      final file = File('${dir.path}/$fileName');

      if (file.existsSync() && file.lengthSync() > 1000) {
        print('[ تخطي ] $fileName موجود مسبقاً.');
        continue;
      }

      print('جاري تحميل $fileName...');
      try {
        final request = await client.getUrl(Uri.parse('$baseUrl$pageStr.png'));
        final response = await request.close();
        await response.pipe(file.openWrite());
        print('[ نجاح ] تم تحميل $fileName بنجاح.');
      } catch (e) {
        print('[ خطأ ] فشل في تحميل $fileName: $e');
      }
    }

    print('\n✅ اكتملت العملية بنجاح!');
    print('==============================');
    print('الآن تستطيع إعادة تشغيل التطبيق بأمر flutter run!');
  });
}
