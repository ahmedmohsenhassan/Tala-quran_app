import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_text_service.dart';
import '../utils/app_colors.dart';

/// شاشة القراءة النصية (Text Reading Screen)
/// Displays the actual Arabic text of the Surah
class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranTextService _textService = QuranTextService();
  late Future<Map<String, dynamic>> _surahData;

  @override
  void initState() {
    super.initState();
    _surahData = _textService.getSurahDetail(widget.surahNumber);
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
        body: FutureBuilder<Map<String, dynamic>>(
          future: _surahData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold));
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                  child: Text('خطأ في تحميل البيانات',
                      style: TextStyle(color: Colors.white)));
            }

            final data = snapshot.data!;
            final List ayahs = data['ayahs'] ?? [];

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ayah['text'],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              '${ayah['number']}',
                              style: const TextStyle(
                                  color: AppColors.gold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
