import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // المصدر الموثوق الجديد
  final String _baseUrl =
      'https://raw.githubusercontent.com/GovarJabbar/Quran-PNG/master/';

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
      _statusMessage = 'جاري تحضير التحميل من المصدر الموثوق...';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final mushafDir = Directory('${dir.path}/mushaf_pages');
      if (!await mushafDir.exists()) {
        await mushafDir.create(recursive: true);
      }

      final dio = Dio();

      const batchSize = 8; // تقليل العدد قليلاً لضمان الاستقرار
      for (int i = 1; i <= _totalPages; i += batchSize) {
        if (!mounted) return;

        final futures = <Future>[];
        for (int j = 0; j < batchSize && (i + j) <= _totalPages; j++) {
          final pageNumber = i + j;
          final paddedNumber = pageNumber.toString().padLeft(3, '0');
          // الاسم في GitHub هو 001.png والاسم المحلي هو page001.png
          final fileUrl = '$_baseUrl$pageNumber.png';
          final filePath = '${mushafDir.path}/page$paddedNumber.png';

          final file = File(filePath);

          // التحقق من صحة الملف إذا كان موجوداً (ليس HTML)
          if (await file.exists() && await file.length() < 5000) {
            await file.delete();
          }

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
            }).catchError((e) {
              debugPrint('فشل تحميل صفحة $pageNumber: $e');
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
          _statusMessage = 'اكتمل تحميل المصحف بنجاح!';
        });
        await Future.delayed(const Duration(seconds: 1));
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = 'حدث خطأ: $e\nيرجى التحقق من الاتصال بالإنترنت.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.emerald.withValues(alpha: 0.2),
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة فخمة - Premium Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emerald.withValues(alpha: 0.1),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.cloud_download_rounded,
                      size: 80,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'المصحف الإلكتروني',
                    style: GoogleFonts.amiri(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  if (_isDownloading) ...[
                    // شريط التحميل المطور - Enhanced Progress Bar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.gold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(_progress * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.outfit(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '$_downloadedCount / $_totalPages',
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.gold.withValues(alpha: 0.4),
                      ),
                      child: Text(
                        'بدء التحميل الآن',
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _navigateToHome,
                      child: Text(
                        'تخطي التحميل الآن',
                        style: GoogleFonts.amiri(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
