import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'main_nav_screen.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage =
      'للعمل بدون إنترنت، يجب تحميل صفحات المصحف عالية الجودة.';
  final int _totalPages = 604;
  int _downloadedCount = 0;

  final String _baseUrl =
      'https://raw.githubusercontent.com/quran/quran.com-images/master/width_1024/page';

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyDownloaded();
  }

  Future<void> _checkIfAlreadyDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final isDownloaded = prefs.getBool('mushaf_downloaded') ?? false;

    if (isDownloaded) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'جاري تحضير التحميل...';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final mushafDir = Directory('${dir.path}/mushaf_pages');
      if (!await mushafDir.exists()) {
        await mushafDir.create(recursive: true);
      }

      final dio = Dio();

      // We will download in parallel batches to speed it up (e.g. 10 files at a time)
      const batchSize = 10;
      for (int i = 1; i <= _totalPages; i += batchSize) {
        if (!mounted) return; // if user left screen

        final futures = <Future>[];
        for (int j = 0; j < batchSize && (i + j) <= _totalPages; j++) {
          final pageNumber = i + j;
          final paddedNumber = pageNumber.toString().padLeft(3, '0');
          final fileUrl = '$_baseUrl$paddedNumber.png';
          final filePath = '${mushafDir.path}/page$paddedNumber.png';

          final file = File(filePath);
          if (!await file.exists()) {
            futures.add(dio.download(fileUrl, filePath).then((_) {
              _downloadedCount++;
              if (mounted) {
                setState(() {
                  _progress = _downloadedCount / _totalPages;
                  _statusMessage =
                      'جاري تحميل الصفحة $_downloadedCount من $_totalPages';
                });
              }
            }));
          } else {
            _downloadedCount++;
            if (mounted) {
              setState(() {
                _progress = _downloadedCount / _totalPages;
              });
            }
          }
        }
        await Future.wait(futures);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mushaf_downloaded', true);

      if (mounted) {
        setState(() {
          _statusMessage = 'اكتمل التحميل بنجاح!';
        });
        await Future.delayed(const Duration(seconds: 1));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'حدث خطأ أثناء التحميل: $e\nيرجى المحاولة مرة أخرى.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book,
                size: 80,
                color: AppColors.gold,
              ),
              const SizedBox(height: 24),
              const Text(
                'تجهيز التطبيق للعمل بدون إنترنت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(height: 48),
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 10,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _startDownload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'بدء التحميل (حوالي 60MB)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
