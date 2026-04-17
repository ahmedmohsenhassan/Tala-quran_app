import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/reading_service.dart';
import 'main_dashboard_screen.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'اختر الرواية التي تود تحميلها للعمل بدون إنترنت.';
  String _selectedReading = ReadingService.hafs;
  final int _totalPages = 604;
  int _downloadedCount = 0;

  // المصادر
  final Map<String, String> _sources = {
    ReadingService.hafs: 'https://raw.githubusercontent.com/GovarJabbar/Quran-PNG/master/',
    ReadingService.warsh: 'https://raw.githubusercontent.com/QuranHub/quran-pages-images/master/warsh_png/',
  };

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // إذا كان هناك تحميل قديم بدون تحديد الرواية، نعتبره حفص
    final isAnyDownloaded = prefs.getBool('mushaf_downloaded') ?? false;
    if (isAnyDownloaded && !prefs.containsKey('mushaf_downloaded_hafs')) {
      await prefs.setBool('mushaf_downloaded_hafs', true);
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadedCount = 0;
      _progress = 0;
      _statusMessage = 'جاري تحضير تحميل مصحف $_selectedReading...';
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final folderName = _selectedReading == ReadingService.hafs ? 'mushaf_hafs' : 'mushaf_warsh';
      final mushafDir = Directory('${dir.path}/$folderName');
      
      if (!await mushafDir.exists()) {
        await mushafDir.create(recursive: true);
      }

      final dio = Dio();
      final baseUrl = _sources[_selectedReading]!;

      const batchSize = 10; 
      for (int i = 1; i <= _totalPages; i += batchSize) {
        if (!mounted) return;

        final futures = <Future>[];
        for (int j = 0; j < batchSize && (i + j) <= _totalPages; j++) {
          final pageNumber = i + j;
          final paddedNumber = pageNumber.toString().padLeft(3, '0');
          
          // المصدر الخاص بحفص يستخدم 001.png، وورش قد يستخدم 1.png أو 001.png
          // QuranHub يستخدم 1.png بدون أصفار بادئة في بعض المجلدات، سنتأكد
          String fileName = paddedNumber;
          if (_selectedReading == ReadingService.warsh) {
             fileName = pageNumber.toString(); // QuranHub style
          }
          
          final fileUrl = '$baseUrl$fileName.png';
          final localFileName = 'page$paddedNumber.png';
          final filePath = '${mushafDir.path}/$localFileName';

          final file = File(filePath);
          if (!await file.exists()) {
            futures.add(dio.download(fileUrl, filePath).then((_) {
              _downloadedCount++;
              if (mounted) {
                setState(() {
                  _progress = _downloadedCount / _totalPages;
                  _statusMessage = 'جاري تحميل صفحة $_downloadedCount من $_totalPages';
                });
              }
            }).catchError((e) {
              debugPrint('فشل تحميل صفحة $pageNumber في $_selectedReading: $e');
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
      final key = 'mushaf_downloaded_${_selectedReading == ReadingService.hafs ? 'hafs' : 'warsh'}';
      await prefs.setBool(key, true);
      await prefs.setBool('mushaf_downloaded', true); // Global flag

      if (mounted) {
        setState(() {
          _statusMessage = 'اكتمل تحميل مصحف $_selectedReading بنجاح!';
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'تحميل المصحف',
            style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.emerald.withValues(alpha: 0.1),
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeaderIcon(),
                  const SizedBox(height: 32),
                  _buildReadingSelector(),
                  const SizedBox(height: 32),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(fontSize: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 48),
                  if (_isDownloading) _buildProgressBar() else _buildDownloadButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.emerald.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.cloud_download_rounded, size: 80, color: AppColors.gold),
    );
  }

  Widget _buildReadingSelector() {
    return Row(
      children: [
        _buildReadingCard(ReadingService.hafs, 'مصحف حفص', Icons.menu_book),
        const SizedBox(width: 16),
        _buildReadingCard(ReadingService.warsh, 'مصحف ورش', Icons.library_books),
      ],
    );
  }

  Widget _buildReadingCard(String reading, String label, IconData icon) {
    bool isSelected = _selectedReading == reading;
    return Expanded(
      child: InkWell(
        onTap: _isDownloading ? null : () => setState(() => _selectedReading = reading),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emerald.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.gold, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.amiri(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(_progress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('$_downloadedCount / $_totalPages',
                style: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloadButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _startDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          child: Text('بدء التحميل الآن', style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _navigateToHome,
          child: Text('تخطي التحميل الآن', style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 16)),
        ),
      ],
    );
  }
}
