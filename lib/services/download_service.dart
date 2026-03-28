import 'dart:io';
import 'dart:ui';
import 'package:tala_quran_app/models/reciter_model.dart';
import 'package:tala_quran_app/services/audio_url_service.dart';
import 'dart:isolate';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

/// خدمة التحميل — Download Service
/// مسؤول عن إدارة تحميل صفحات المصحف، بيانات الإحداثيات، والتزامن الصوتي
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  static const String _pageImageBaseUrl = 'https://quran.com/images/pages/'; // Example: 001.png

  /// تهيئة محرك التحميل
  static Future<void> initialize() async {
    // Initialized in main.dart
  }

  @pragma('vm:entry-point')
  static void callback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  /// تحميل سورة (صوت) لـ قارئ محدد
  Future<void> downloadAudio({required Reciter reciter, required int surahNumber}) async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio/${reciter.id}');
    if (!await audioDir.exists()) await audioDir.create(recursive: true);

    final surahStr = surahNumber.toString().padLeft(3, '0');
    final url = AudioUrlService.getSurahUrl(reciter: reciter, surahNumber: surahNumber);

    await FlutterDownloader.enqueue(
      url: url,
      savedDir: audioDir.path,
      fileName: '$surahStr.mp3',
      showNotification: true,
      openFileFromNotification: false,
    );
  }

  /// تحميل صفحة مصحف كاملة (صورة + بيانات)
  Future<void> downloadPage(int pageNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final mushafDir = Directory('${directory.path}/mushaf/$pageNumber');
    
    if (!await mushafDir.exists()) {
      await mushafDir.create(recursive: true);
    }

    final pageStr = pageNumber.toString().padLeft(3, '0');
    
    // 1. تحميل الصورة (KFGQPC Madani)
    await FlutterDownloader.enqueue(
      url: '$_pageImageBaseUrl$pageStr.png',
      savedDir: mushafDir.path,
      fileName: 'page_$pageStr.png',
      showNotification: true,
      openFileFromNotification: false,
    );
  }

  /// التحقق من تحميل الجزء بالكامل
  Future<bool> isJuzDownloaded(int juzNumber) async {
    // الجزء 1 مثلاً من صفحة 1 لـ 21 (تبسيط للمثال)
    // في الواقع سنستخدم QuranPageHelper لمعرفة الصفحات
    return await getLocalPageImage(1) != null; 
  }

  /// حساب حجم الذاكرة المستخدمة للقرآن (ميجابايت)
  Future<double> getUsedSpaceMB() async {
    final directory = await getApplicationDocumentsDirectory();
    final mushafDir = Directory('${directory.path}/mushaf');
    final audioDir = Directory('${directory.path}/audio');
    
    int totalBytes = 0;
    if (await mushafDir.exists()) {
      await for (var file in mushafDir.list(recursive: true)) {
        if (file is File) totalBytes += await file.length();
      }
    }
    if (await audioDir.exists()) {
      await for (var file in audioDir.list(recursive: true)) {
        if (file is File) totalBytes += await file.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }

  /// التحقق من وجود الصفحة محلياً
  Future<File?> getLocalPageImage(int pageNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final pageStr = pageNumber.toString().padLeft(3, '0');
    final file = File('${directory.path}/mushaf/$pageNumber/page_$pageStr.png');
    
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// مسح صفحة لتوفير مساحة
  Future<void> deletePage(int pageNumber) async {
    final directory = await getApplicationDocumentsDirectory();
    final mushafDir = Directory('${directory.path}/mushaf/$pageNumber');
    if (await mushafDir.exists()) {
      await mushafDir.delete(recursive: true);
    }
  }

  /// مسح جميع الصوتيات
  Future<void> clearAllAudio() async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio');
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
  }
}
