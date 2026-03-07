import 'dart:ui';
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
        backgroundColor: AppColors.cream,
        extendBodyBehindAppBar: true,
        appBar: _buildGlassAppBar(),
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
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
              itemCount: ayahs.length,
              itemBuilder: (context, index) {
                final ayah = ayahs[index];
                return _buildAyahItem(ayah, index == 0);
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: AppColors.emerald.withValues(alpha: 0.8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.gold, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.surahName,
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
        ),
      ),
    );
  }

  Widget _buildAyahItem(Map<String, dynamic> ayah, bool isFirst) {
    return Column(
      children: [
        if (isFirst && widget.surahNumber != 1 && widget.surahNumber != 9)
          Padding(
            padding: const EdgeInsets.only(bottom: 30, top: 20),
            child: Text(
              "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                color: AppColors.emerald,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Text(
                ayah['text'],
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  color: AppColors.emerald,
                  fontSize: 28,
                  height: 1.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.brightness_7_rounded,
                          color: AppColors.gold.withValues(alpha: 0.2),
                          size: 40),
                      Text(
                        '${ayah['number']}',
                        style: GoogleFonts.outfit(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  thickness: 1,
                  indent: 40,
                  endIndent: 40),
            ],
          ),
        ),
      ],
    );
  }
}
