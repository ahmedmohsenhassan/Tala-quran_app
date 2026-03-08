import 'dart:ui';
import 'package:flutter/gestures.dart';
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

  void _showTafseer(int ayahNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تفسير الآية $ayahNumber',
              style: GoogleFonts.amiri(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<String>(
                future: _textService.getTafseer(widget.surahNumber, ayahNumber),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.gold));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('خطأ: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)));
                  }

                  // تنظيف النص من وسوم HTML إن وجدت
                  // Clean HTML tags if any
                  String tafseerText = snapshot.data ?? "لا يوجد تفسير.";
                  tafseerText =
                      tafseerText.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '');

                  return SingleChildScrollView(
                    child: Text(
                      tafseerText,
                      style: GoogleFonts.amiri(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('خطأ في تحميل البيانات: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final List ayahs = data['ayahs'] ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
              child: Column(
                children: [
                  if (widget.surahNumber != 1 && widget.surahNumber != 9)
                    _buildBasmalah(),
                  const SizedBox(height: 20),
                  _buildMushafText(ayahs),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBasmalah() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Text(
        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(
          color: AppColors.emerald,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMushafText(List ayahs) {
    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: ayahs.map((ayah) {
          final int number = ayah['number'] ?? 0;
          return TextSpan(
            children: [
              TextSpan(
                text: ayah['text'] + " ",
                style: GoogleFonts.amiri(
                  color: AppColors.emerald,
                  fontSize: 26,
                  height: 2.2,
                  fontWeight: FontWeight.w500,
                ),
                recognizer: LongPressGestureRecognizer()
                  ..onLongPress = () => _showTafseer(number),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _buildVerseMarker(number),
              ),
              const TextSpan(text: " "),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVerseMarker(int number) {
    return GestureDetector(
      onTap: () => _showTafseer(number),
      child: Container(
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.5), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.brightness_7_rounded,
                color: AppColors.gold.withValues(alpha: 0.15), size: 28),
            Text(
              '$number',
              style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
}
