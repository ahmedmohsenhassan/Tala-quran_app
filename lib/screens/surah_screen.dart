import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/audio_service.dart';
import '../services/bookmark_service.dart';
import '../widgets/audio_player_widget.dart';
import '../services/audio_url_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة عرض آيات السورة مع مشغّل صوت
/// Screen to display Surah ayahs with audio player
class SurahScreen extends StatefulWidget {
  final String surahName;
  final int surahNumber;

  const SurahScreen({
    super.key,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<Map<String, dynamic>> ayahs = [];
  bool isLoading = true;
  String? errorMessage;
  String? audioUrl;

  @override
  void initState() {
    super.initState();
    _loadSurahData();
    // حفظ آخر سورة تمت قراءتها
    BookmarkService.saveLastRead(
      surahNumber: widget.surahNumber,
      surahName: widget.surahName,
    );
  }

  @override
  void dispose() {
    AudioService().stop();
    super.dispose();
  }

  /// تحميل بيانات السورة وتوليد رابط الصوت
  Future<void> _loadSurahData() async {
    try {
      // تحميل القارئ المفضل
      final prefs = await SharedPreferences.getInstance();
      final reciterId = prefs.getString('selected_reciter_id') ?? 'al_afasy';
      final reciter = AudioUrlService.getReciterById(reciterId);

      // توليد رابط الصوت الموثوق
      setState(() {
        audioUrl = AudioUrlService.getSurahUrl(
          reciter: reciter,
          surahNumber: widget.surahNumber,
        );
      });

      // تحميل بيانات الآيات من ملف JSON المحلي (كقاعدة نصوص)
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestContent);

      for (final key in manifest.keys) {
        if (key.startsWith('assets/surahs/') && key.endsWith('.json')) {
          try {
            final content = await rootBundle.loadString(key);
            final data = json.decode(content);
            if (data['number'] == widget.surahNumber) {
              final List<dynamic> rawAyahs = data['ayahs'] ?? [];
              setState(() {
                ayahs = rawAyahs.cast<Map<String, dynamic>>();
                isLoading = false;
              });
              return;
            }
          } catch (_) {
            continue;
          }
        }
      }

      setState(() {
        errorMessage = 'لم يتم العثور على بيانات السورة';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء تحميل البيانات: $e';
        isLoading = false;
      });
    }
  }

  void _addBookmark(int ayahNumber) {
    BookmarkService.addBookmark(
      surahNumber: widget.surahNumber,
      surahName: widget.surahName,
      ayahNumber: ayahNumber,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ العلامة - آية $ayahNumber',
          style: GoogleFonts.amiri(color: Colors.white),
        ),
        backgroundColor: AppColors.cardBackground,
        duration: const Duration(seconds: 2),
      ),
    );
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
          title: Text(
            widget.surahName,
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.gold),
        ),
        body: Column(
          children: [
            // محتوى الآيات - Ayahs content
            Expanded(child: _buildBody()),

            // مشغّل الصوت - Audio player
            AudioPlayerWidget(
              audioUrl: audioUrl,
              surahName: widget.surahName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            errorMessage!,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // بسملة في الأعلى (لغير سورة التوبة)
    // Bismillah at the top (except for At-Tawbah)
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: (widget.surahNumber != 9 && widget.surahNumber != 1)
          ? ayahs.length + 1
          : ayahs.length,
      itemBuilder: (context, index) {
        if (widget.surahNumber != 9 && widget.surahNumber != 1 && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Center(
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final ayahIndex = (widget.surahNumber != 9 && widget.surahNumber != 1)
            ? index - 1
            : index;
        final ayah = ayahs[ayahIndex];

        return GestureDetector(
          onLongPress: () => _addBookmark(ayah['number']),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // رقم الآية
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${ayah['number']}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // نص الآية
                Expanded(
                  child: Text(
                    ayah['text'] ?? '',
                    style: GoogleFonts.amiri(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      height: 2.0,
                    ),
                    textAlign: TextAlign.right,
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
