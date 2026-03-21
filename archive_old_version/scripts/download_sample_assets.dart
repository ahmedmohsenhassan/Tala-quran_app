// ignore_for_file: avoid_print
import 'dart:io';

/// سكريبت الأداة المساعدة (Utilities)
/// لتحميل أول 5 صفحات (عينة المطور) ووضعها في مجلد assets/mushaf محلياً على الكمبيوتر
/// بدلاً من استخدام الـ Terminal.
void main() async {
  print('جاري تهيئة مجلد assets/mushaf...');
  final dir = Directory('assets/mushaf');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final client = HttpClient();
  // المصدر الموثوق لصور مصحف المدينة عالي الجودة
  const baseUrl =
      'https://raw.githubusercontent.com/GovarJabbar/Quran-PNG/master/';

  print(
      'جاري تهيئة الاتصال وتنزيل الـ 5 صفحات المدمجة (يجب أن يعمل هذا الملف على جهازك الشخصي، وليس المحاكي)...');

  for (int i = 1; i <= 5; i++) {
    final pageStr = i.toString().padLeft(3, '0');
    final fileName = 'page$pageStr.png'; // الاسم المحلي
    final remoteName = '$pageStr.png'; // الاسم في المستودع
    final file = File('${dir.path}/$fileName');

    // حذف الملفات التالفة (التي تحتوي على 404 أو HTML)
    if (file.existsSync() && file.lengthSync() < 5000) {
      print('حذف ملف تالف: $fileName');
      file.deleteSync();
    }

    if (file.existsSync()) {
      print('[ تخطي ] $fileName موجود مسبقاً.');
      continue;
    }

    print('جاري تحميل $fileName من $baseUrl$remoteName...');
    try {
      final request = await client.getUrl(Uri.parse('$baseUrl$remoteName'));
      final response = await request.close();
      if (response.statusCode == 200) {
        await response.pipe(file.openWrite());
        print(
            '[ نجاح ] تم تحميل $fileName بنجاح (${file.lengthSync()} bytes).');
      } else {
        print(
            '[ خطأ ] فشل في تحميل $fileName: كود الاستجابة ${response.statusCode}');
      }
    } catch (e) {
      print('[ خطأ ] فشل في تحميل $fileName: $e');
    }
  }

  print('\n✅ اكتملت العملية بنجاح!');
  print('==============================');
  print(
      'يمكنك الآن تشغيل أو إعادة تشغيل التطبيق على المحاكي،\nوستجد أن أول 5 صفحات تعمل فوراً من داخل التطبيق بدون ظهور شاشة الخطأ المتعلقة بالإنترنت.');
}
