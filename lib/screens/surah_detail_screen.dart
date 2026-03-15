import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_text_service.dart';
import '../services/translation_service.dart';
import '../services/tafseer_service.dart';
import '../utils/app_colors.dart';
import '../main.dart'; // للوصول لـ fontSizeNotifier
import '../services/theme_service.dart';

/// شاشة القراءة النصية (Text Reading Screen)
/// Displays the actual Arabic text of the Surah
class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  final int? highlightedAyah;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
    this.highlightedAyah,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranTextService _textService = QuranTextService();
  late Future<Map<String, dynamic>> _surahData;
  bool _isTranslationEnabled = false;

  // مفاتيح لتحديد موقع الآيات من أجل التمرير التلقائي
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void initState() {
    super.initState();
    _surahData = _textService.getSurahDetail(widget.surahNumber);
    _loadTranslationsIfNeeded();
  }

  Future<void> _loadTranslationsIfNeeded() async {
    _isTranslationEnabled = await TranslationService.isTranslationEnabled();
    if (_isTranslationEnabled) {
      final langId = await TranslationService.getTranslationLanguage();
      final surahData = await _surahData;
      try {
        if (surahData.containsKey('ayahs')) {
          final List ayahs = surahData['ayahs'];
          Map<int, String> transMap = {};
          
          final futures = ayahs.map((ayah) async {
            final int number = ayah['number'] ?? 0;
            final text = await _textService.getTranslation(widget.surahNumber, number, langId);
            return MapEntry(number, text);
          });
          
          final results = await Future.wait(futures);
          for (var entry in results) {
            transMap[entry.key] = entry.value;
          }
          
        }
      } catch (e) {
        // Handle gracefully
      }
    }
    
    if (widget.highlightedAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlightedAyah();
      });
    }
  }

  void _scrollToHighlightedAyah() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final key = _ayahKeys[widget.highlightedAyah];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
    });
  }

  void _showTafseer(int ayahNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تفسير الآية $ayahNumber',
                        style: GoogleFonts.amiri(
                          color: AppColors.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // اختيار التفسير
                      FutureBuilder<int>(
                        future: TafseerService.getTafseerId(),
                        builder: (context, tafseerPrefSnapshot) {
                          if (!tafseerPrefSnapshot.hasData) {
                            return const SizedBox();
                          }
                          return DropdownButton<int>(
                            value: tafseerPrefSnapshot.data,
                            dropdownColor: AppColors.cardBackground,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
                            underline: const SizedBox(),
                            style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 16),
                            items: TafseerService.availableTafseers.entries.map((entry) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: (newTafseerId) async {
                              if (newTafseerId != null) {
                                await TafseerService.setTafseerId(newTafseerId);
                                setModalState(() {}); // إعادة بناء نافذة التفسير
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  Expanded(
                    child: FutureBuilder<Map<String, String>>(
                      future: _textService.getTafseer(widget.surahNumber, ayahNumber),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(color: AppColors.gold));
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('خطأ: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red)));
                        }

                        // تنظيف النص من وسوم HTML إن وجدت
                        String tafseerText = snapshot.data?['text'] ?? "لا يوجد تفسير.";
                        tafseerText = tafseerText.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), '');

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ValueListenableBuilder<double>(
                            valueListenable: fontSizeNotifier,
                            builder: (context, multiplier, child) {
                              return Text(
                                tafseerText,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.amiri(
                                  color: AppColors.textPrimary,
                                  fontSize: 20 * multiplier,
                                  height: 1.8,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ValueListenableBuilder<String>(
        valueListenable: fontNotifier,
        builder: (context, currentFont, _) {
          String fontFamily = currentFont;
          if (currentFont == ThemeService.fontNaskh) {
            fontFamily = 'Noto Naskh Arabic';
          }

          return ValueListenableBuilder<double>(
            valueListenable: fontSizeNotifier,
            builder: (context, multiplier, _) {
              return Scaffold(
                backgroundColor: AppColors.bg(context),
                extendBodyBehindAppBar: true,
                appBar: _buildGlassAppBar(),
                body: FutureBuilder<Map<String, dynamic>>(
                  future: _surahData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.gold));
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
                            _buildBasmalah(fontFamily),
                          const SizedBox(height: 20),
                          _buildMushafText(ayahs, fontFamily, multiplier),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBasmalah(String fontFamily) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Text(
        "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.gold,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMushafText(List ayahs, String fontFamily, double multiplier) {
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
                style: TextStyle(
                  fontFamily: fontFamily,
                  color: AppColors.text(context),
                  fontSize: 26 * multiplier,
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
            backgroundColor: AppColors.bg(context).withValues(alpha: 0.8),
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
