import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reciter_model.dart';
import '../services/quran_database_service.dart';
import '../services/quran_resource_service.dart';
import '../services/tafseer_service.dart';
import '../services/audio_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';

class OfflineLibraryScreen extends StatefulWidget {
  const OfflineLibraryScreen({super.key});

  @override
  State<OfflineLibraryScreen> createState() => _OfflineLibraryScreenState();
}

class _OfflineLibraryScreenState extends State<OfflineLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final QuranDatabaseService _db = QuranDatabaseService();
  final QuranResourceService _resourceService = QuranResourceService();
  final AudioService _audioService = AudioService();

  List<Map<String, dynamic>> _tafseers = [];
  List<Map<String, dynamic>> _translations = [];
  bool _isLoading = true;

  Reciter? _selectedReciter;
  final List<Reciter> _allReciters = Reciter.defaultReciters;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    
    final tafseersList = TafseerService.availableTafseers.entries.map((e) {
      return {
        'id': e.key,
        'name': e.value,
        'identifier': _getTafseerIdentifier(e.key),
        'type': 'tafseer',
        'isDownloaded': false,
      };
    }).toList();

    final translationsList = [
      {'id': 131, 'name': 'English - Sahih International', 'identifier': 'en-sahih', 'type': 'translation'},
      {'id': 139, 'name': 'English - Yusuf Ali', 'identifier': 'en-yusuf-ali', 'type': 'translation'},
      {'id': 167, 'name': 'English - Clear Quran', 'identifier': 'en-clear', 'type': 'translation'},
    ].map((e) => {...e, 'isDownloaded': false}).toList();

    for (var item in tafseersList) {
      item['isDownloaded'] = await _db.isResourceDownloaded(item['identifier'] as String);
    }
    for (var item in translationsList) {
      item['isDownloaded'] = await _db.isResourceDownloaded(item['identifier'] as String);
    }

    if (mounted) {
      setState(() {
        _tafseers = tafseersList;
        _translations = translationsList;
        _isLoading = false;
      });
    }
  }

  String _getTafseerIdentifier(int id) {
    switch (id) {
      case 16: return 'ar-tafseer-muyassar';
      case 169: return 'ar-tafsir-ibn-kathir';
      default: return 'tafseer-$id';
    }
  }

  Future<void> _handleDownload(Map<String, dynamic> resource) async {
    final name = resource['name'] as String;
    final id = resource['id'] as int;
    final identifier = resource['identifier'] as String;
    final type = resource['type'] as String;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('بدأ تحميل $name... 🚀'))
    );

    try {
      if (type == 'tafseer') {
        await _resourceService.downloadTafseer(id, identifier, name);
      } else {
        await _resourceService.downloadTranslation(id, identifier, name);
      }
      await _loadResources();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ اكتمل تحميل $name!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ فشل التحميل: $e')));
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
          title: Text(
            'المكتبة والأوفلاين',
            style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.gold),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'الكتب والتفاسير', icon: Icon(Icons.book_rounded)),
              Tab(text: 'التلاوات الصوتية', icon: Icon(Icons.mic_external_on_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTextTab(),
            _buildAudioTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('التفاسير العربية', Icons.book_rounded),
            TextButton.icon(
              onPressed: () {
                for (var t in _tafseers) {
                  if (!t['isDownloaded']) _handleDownload(t);
                }
              },
              icon: const Icon(Icons.download_done_rounded, size: 16, color: AppColors.gold),
              label: const Text('تحميل الكل', style: TextStyle(color: AppColors.gold, fontSize: 12)),
            ),
          ],
        ),
        ..._tafseers.map((t) => _buildResourceCard(t)),
        
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('تراجم اللغات', Icons.translate_rounded),
            TextButton.icon(
              onPressed: () {
                for (var t in _translations) {
                  if (!t['isDownloaded']) _handleDownload(t);
                }
              },
              icon: const Icon(Icons.download_done_rounded, size: 16, color: AppColors.gold),
              label: const Text('تحميل الكل', style: TextStyle(color: AppColors.gold, fontSize: 12)),
            ),
          ],
        ),
        ..._translations.map((t) => _buildResourceCard(t)),
      ],
    );
  }

  Widget _buildAudioTab() {
    return Column(
      children: [
        // Reciter Selection
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _allReciters.length,
            itemBuilder: (context, index) {
              final r = _allReciters[index];
              final isSelected = _selectedReciter?.id == r.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedReciter = r),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isSelected ? AppColors.gold : Colors.white10,
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(r.imageUrl),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        r.name.split(' ').last,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.gold : Colors.white70,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        const Divider(color: Colors.white10),
        
        Expanded(
          child: _selectedReciter == null
            ? const Center(child: Text('اختر قارئاً لإدارة التحميلات', style: TextStyle(color: Colors.grey)))
            : _buildSurahDownloadList(),
        ),
      ],
    );
  }

  Widget _buildSurahDownloadList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 114,
      itemBuilder: (context, index) {
        final surahNum = index + 1;
        final name = QuranPageHelper.surahNames[index];
        return FutureBuilder<bool>(
          future: _audioService.isSurahDownloaded(_selectedReciter!.id, surahNum),
          builder: (context, snapshot) {
            final isDown = snapshot.data ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDown ? AppColors.emerald.withValues(alpha: 0.2) : Colors.white12),
              ),
              child: Row(
                children: [
                  Text('$surahNum.', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('سورة $name', style: GoogleFonts.amiri(color: Colors.white, fontSize: 16)),
                  ),
                  if (isDown)
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                  else
                    IconButton(
                      icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.gold),
                      onPressed: () async {
                        try {
                          await _resourceService.downloadSurahAudio(
                            reciter: _selectedReciter!,
                            surahNumber: surahNum,
                            surahName: name,
                          );
                          if (context.mounted) setState(() {}); // Refresh list
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                          }
                        }
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final bool isDownloaded = resource['isDownloaded'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDownloaded ? AppColors.emerald.withValues(alpha: 0.3) : AppColors.gold.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource['name'] as String, style: GoogleFonts.amiri(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(isDownloaded ? Icons.check_circle_rounded : Icons.cloud_off_rounded, size: 14, color: isDownloaded ? Colors.green : Colors.grey),
                    const SizedBox(width: 6),
                    Text(isDownloaded ? 'متاح أوفلاين' : 'يتطلب تحميل', style: GoogleFonts.amiri(color: isDownloaded ? Colors.green : Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (!isDownloaded)
            ElevatedButton(
              onPressed: () => _handleDownload(resource),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('تحميل'),
            ),
        ],
      ),
    );
  }
}
