import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/quran_page_helper.dart';
import '../utils/app_colors.dart';
import '../services/audio_service.dart';
import '../services/audio_url_service.dart';
import '../models/reciter_model.dart';
import 'mushaf_viewer_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<dynamic> _surahs = [];
  bool _isLoading = true;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _loadSurahData();
  }

  Future<void> _loadSurahData() async {
    final String response = await rootBundle.loadString('assets/data/surahs.json');
    final data = await json.decode(response);
    if (mounted) {
      setState(() {
        _surahs = data;
        _isLoading = false;
      });
    }
  }

  void _playFirstAyah(int surahId) async {
    final reciter = Reciter.defaultReciters.first; 
    final url = AudioUrlService.getAyahUrl(
      reciterBaseUrl: reciter.baseUrl,
      surahNumber: surahId,
      ayahNumber: 1,
    );
    
    await _audioService.playAudioWithMeta(
      url: url,
      id: "surah_\$surahId_ayah_1",
      title: "سورة \${_surahs[surahId - 1]['name']}",
      artist: reciter.name,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("جاري تشغيل البسملة... 🎧", style: GoogleFonts.amiri()),
          backgroundColor: AppColors.gold.withValues(alpha: 0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF001A16), // Deeper Green
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'تلا القرآن',
            style: GoogleFonts.amiri(
              textStyle: const TextStyle(
                color: AppColors.gold,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF001A16), AppColors.emerald.withValues(alpha: 0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _surahs.length,
              itemBuilder: (context, index) {
                final surah = _surahs[index];
                final int id = surah['id'];

                return _buildSurahCard(surah, id);
              },
            ),
      ),
    );
  }

  Widget _buildSurahCard(dynamic surah, int id) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final page = QuranPageHelper.getPageForSurah(id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MushafViewerScreen(initialPage: page),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // 🏁 Surah Number Badge
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$id',
                        style: GoogleFonts.outfit(
                          color: AppColors.gold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // 📝 Surah Names
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah['name'],
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          surah['englishName'],
                          style: GoogleFonts.outfit(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🎧 Play Button
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled_rounded, color: AppColors.gold, size: 36),
                    onPressed: () => _playFirstAyah(id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
