import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/content_download_service.dart';
import '../services/quran_database_service.dart';
import '../utils/app_colors.dart';

class ContentManagerScreen extends StatefulWidget {
  const ContentManagerScreen({super.key});

  @override
  State<ContentManagerScreen> createState() => _ContentManagerScreenState();
}

class _ContentManagerScreenState extends State<ContentManagerScreen> {
  final QuranDatabaseService _db = QuranDatabaseService();
  final List<String> _downloadedIdentifiers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    // Fetch all resources and filter for downloaded ones
    // We'll simplify this for the demo by just checking our popular ones
    _downloadedIdentifiers.clear();
    for (var item in _availableContent) {
      final isDown = await _db.isResourceDownloaded(item['id']);
      if (isDown) _downloadedIdentifiers.add(item['id']);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  final List<Map<String, dynamic>> _availableContent = [
    {
      'id': 'translation-131',
      'name': 'English (Sahih International)',
      'type': 'translation',
      'lang': 'en',
      'api_id': 131,
    },
    {
      'id': 'translation-139',
      'name': 'English (Yusuf Ali)',
      'type': 'translation',
      'lang': 'en',
      'api_id': 139,
    },
    {
      'id': 'translation-97',
      'name': 'Urdu (Abul A\'la Maududi)',
      'type': 'translation',
      'lang': 'ur',
      'api_id': 97,
    },
    {
      'id': 'tafseer-16',
      'name': 'Tafseer Al-Muyassar',
      'type': 'tafseer',
      'lang': 'ar',
      'api_id': 16,
    },
    {
      'id': 'tafseer-1',
      'name': 'Tafseer Ibn Kathir',
      'type': 'tafseer',
      'lang': 'ar',
      'api_id': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final downloadService = Provider.of<ContentDownloadService>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF001A16),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'مدير المحتوى أوفلاين',
            style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            if (downloadService.isDownloading) _buildProgressCard(downloadService),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _availableContent.length,
                    itemBuilder: (context, index) {
                      final item = _availableContent[index];
                      final isDownloaded = _downloadedIdentifiers.contains(item['id']);
                      return _buildContentCard(item, isDownloaded, downloadService);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ContentDownloadService service) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.downloading_rounded, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.statusMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Text(
                '${(service.progress * 100).toInt()}%',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: service.progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> item, bool isDownloaded, ContentDownloadService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(
          item['type'] == 'translation' ? Icons.translate_rounded : Icons.library_books_rounded,
          color: AppColors.gold,
        ),
        title: Text(
          item['name'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          item['type'] == 'translation' ? 'ترجمة (${item['lang']})' : 'تفسير عربي',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: isDownloaded
            ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent)
            : IconButton(
                onPressed: service.isDownloading 
                    ? null 
                    : () async {
                        bool success = false;
                        if (item['type'] == 'translation') {
                          success = await service.downloadTranslation(item['api_id'], item['name'], item['lang']);
                        } else {
                          success = await service.downloadTafseer(item['api_id'], item['name'], item['lang']);
                        }
                        if (success) _loadStatus();
                      },
                icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.gold),
              ),
      ),
    );
  }
}
