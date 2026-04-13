import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tafseer_service.dart';
import '../services/content_download_service.dart';
import '../services/quran_database_service.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';

class TafseerScreen extends StatefulWidget {
  final int surahNumber;
  final int? ayahNumber;

  const TafseerScreen({
    super.key,
    required this.surahNumber,
    this.ayahNumber,
  });

  @override
  State<TafseerScreen> createState() => _TafseerScreenState();
}

class _TafseerScreenState extends State<TafseerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tafseers = [];
  String _error = '';
  String _tafseerName = 'التفسير الميسر';
  int _currentTafseerId = TafseerService.tafseerMuyassar;

  @override
  void initState() {
    super.initState();
    _loadTafseer();
  }

  Future<void> _loadTafseer() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final id = await TafseerService.getTafseerId();
      final results = await TafseerService.getSurahTafseer(widget.surahNumber);
      
      // تحديث حالة التحميل المحلي
      final identifier = 'tafseer-$id';
      final downloaded = await QuranDatabaseService().isResourceDownloaded(identifier);

      if (mounted) {
        setState(() {
          _tafseers = results;
          _isDownloaded = downloaded;
          _currentTafseerId = id;
          _tafseerName = TafseerService.availableTafseers[id] ?? 'تفسير';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل البيانات.';
          _isLoading = false;
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
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: InkWell(
            onTap: _showTafseerSelector, // 🌅 Allow changing from title too
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _tafseerName,
                      style: GoogleFonts.amiri(
                        color: AppColors.gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.gold, size: 18),
                  ],
                ),
                if (!_isLoading && _error.isEmpty)
                  Text(
                    _isDownloaded ? 'وضع الأوفلاين (محمّل)' : 'تحميل من الإنترنت',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: _isDownloaded ? AppColors.emerald : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          centerTitle: true,
          actions: [
            if (!_isLoading) ...[
              _buildDownloadAction(),
              IconButton(
                icon: const Icon(Icons.settings_suggest_outlined, color: AppColors.gold),
                onPressed: _showTafseerSelector,
                tooltip: 'تغيير التفسير',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
                onPressed: _loadTafseer,
                tooltip: 'تحديث',
              ),
            ],
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  bool _isDownloaded = false;

  Widget _buildDownloadAction() {
    return Consumer<ContentDownloadService>(
      builder: (context, downloadService, child) {
        if (downloadService.isDownloading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: downloadService.progress,
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        }

        return IconButton(
          icon: Icon(
            _isDownloaded ? Icons.file_download_done : Icons.cloud_download_outlined,
            color: _isDownloaded ? AppColors.emerald : AppColors.gold,
          ),
          onPressed: _isDownloaded ? null : () => _startDownload(downloadService),
          tooltip: _isDownloaded ? 'محمّل مسبقاً' : 'تنزيل السورة للأوفلاين',
        );
      },
    );
  }

  Future<void> _showTafseerSelector() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر التفسير المفضل',
              style: GoogleFonts.amiri(fontSize: 20, color: AppColors.gold, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.white10),
            ...TafseerService.availableTafseers.entries.map((entry) => ListTile(
              title: Text(entry.value, style: TextStyle(color: entry.key == _currentTafseerId ? AppColors.gold : Colors.white)),
              trailing: entry.key == _currentTafseerId ? const Icon(Icons.check_circle, color: AppColors.gold) : null,
              onTap: () => Navigator.pop(context, entry.key),
            )),
          ],
        ),
      ),
    );

    if (result != null && result != _currentTafseerId) {
      await TafseerService.setTafseerId(result);
      _loadTafseer();
    }
  }

  Future<void> _startDownload(ContentDownloadService service) async {
    final id = await TafseerService.getTafseerId();
    final name = TafseerService.availableTafseers[id] ?? 'تفسير';
    
    final success = await service.downloadTafseer(id, name, 'ar');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحميل التفسير بنجاح! 🎉')),
      );
      _loadTafseer(); // Reload to show offline status
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTafseer,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return _buildTafseerList();
  }

  Widget _buildTafseerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _tafseers.length,
      itemBuilder: (context, index) {
        final item = _tafseers[index];
        final ayahNum = int.tryParse(item['aya'].toString()) ?? 0;
        final isHighlighted = widget.ayahNumber == ayahNum;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.emerald.withValues(alpha: 0.05)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighlighted
                  ? AppColors.gold
                  : AppColors.emerald.withValues(alpha: 0.1),
              width: isHighlighted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'الآية $ayahNum',
                        style: GoogleFonts.outfit(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.gold, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item['text'] ?? 'المحتوى غير متوفر',
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
