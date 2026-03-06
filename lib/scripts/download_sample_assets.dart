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
  const baseUrl =
      'https://raw.githubusercontent.com/quran/quran.com-images/master/width_1024/page';

  print(
      'جاري تهيئة الاتصال وتنزيل الـ 5 صفحات المدمجة (يجب أن يعمل هذا الملف على جهازك الشخصي، وليس المحاكي)...');

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
  print(
      'يمكنك الآن تشغيل أو إعادة تشغيل التطبيق على المحاكي،\nوستجد أن أول 5 صفحات تعمل فوراً من داخل التطبيق بدون ظهور شاشة الخطأ المتعلقة بالإنترنت.');
}
