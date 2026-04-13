import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_text_service.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../services/download_service.dart';
import 'dart:io';
import '../services/ayah_info_service.dart';
import '../services/tajweed_parser.dart';

// ============================================================
//  دالة مركزية للحصول على TextStyle الصحيح لكل خط عربي
// ============================================================
TextStyle getArabicTextStyle({
  required String fontFamily,
  required double fontSize,
  required Color color,
  FontWeight fontWeight = FontWeight.w500,
  double height = 1.5,
  bool forUI = false, // UI elements like headers use simpler style
}) {
  switch (fontFamily) {
    case ThemeService.fontUthmanic:
      // Amiri Quran is properly shaped for Uthmanic scripts with pause marks and exact ligatures.
      return GoogleFonts.amiriQuran(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    case ThemeService.fontNaskh:
      return GoogleFonts.notoNaskhArabic(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    case ThemeService.fontIndopak:
      // IndoPak uses Noto Nastaliq Urdu as closest match
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    case ThemeService.fontAmiri:
    default:
      return GoogleFonts.amiri(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
  }
}

class MushafPageRenderer extends StatefulWidget {
  final int pageNumber;
  final Function(int surah, int ayah)? onAyahTapped;
  final Function(int surah, int ayah)? onAyahLongPressed;
  final int? highlightedAyah;
  final int? highlightedSurah;
  final bool isMemorizationMode;
  final String theme;
  final double fontSize;
  final String fontFamily;
  final String edition;
  final String? highlightedWordLocation;
  final bool showTajweed;
  final PageController? pageController;
  final Function(bool isZoomed)? onZoomChanged;

  const MushafPageRenderer({
    super.key,
    required this.pageNumber,
    this.onAyahTapped,
    this.onAyahLongPressed,
    this.highlightedAyah,
    this.highlightedSurah,
    this.isMemorizationMode = false,
    this.theme = ThemeService.mushafClassic,
    this.fontSize = 24.0,
    this.fontFamily = ThemeService.fontAmiri,
    this.edition = ThemeService.editionMadina1405,
    this.highlightedWordLocation,
    this.showTajweed = false,
    this.pageController,
    this.onZoomChanged,
  });

  @override
  State<MushafPageRenderer> createState() => _MushafPageRendererState();
}

class _MushafPageRendererState extends State<MushafPageRenderer> with TickerProviderStateMixin {
  static const bool showDebugBoxes = false;

  final QuranTextService _quranService = QuranTextService();
  List<Map<String, dynamic>> _pageData = [];
  bool _isLoading = true;
  late TransformationController _transformationController;
  bool _isZoomed = false;
  File? _localImage;
  final DownloadService _downloadService = DownloadService();
  final AyahInfoService _ayahInfoService = AyahInfoService();
  Map<String, List<Rect>> _ayahRects = {};
  Map<int, List<Map<String, dynamic>>> _processedLines = {};
  Map<int, dynamic> _lineMetadata = {};
  late AnimationController _auraController;

  // ─── Font Scale Factor ────────────────────────────────────────────────────
  // Maps slider value (15–50) to a ratio relative to default (24).
  // This ensures the slider is noticeable throughout its range.
  double get _fontScaleRatio => widget.fontSize / 24.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadPageData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _auraController.dispose();
    super.dispose();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if (mounted) {
      if (scale > 1.05 && !_isZoomed) {
        setState(() => _isZoomed = true);
        widget.onZoomChanged?.call(true);
      } else if (scale <= 1.05 && _isZoomed) {
        setState(() => _isZoomed = false);
        widget.onZoomChanged?.call(false);
      }
    }
  }

  @override
  void didUpdateWidget(MushafPageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        oldWidget.showTajweed != widget.showTajweed ||
        oldWidget.fontFamily != widget.fontFamily) {
      _loadPageData();
      _transformationController.value = Matrix4.identity();
      _isZoomed = false;
    }
  }

  Future<void> _loadPageData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _quranService.getPageWords(widget.pageNumber);
      final localImg = await _downloadService.getLocalPageImage(widget.pageNumber);
      final rects = await _ayahInfoService.getPageAyahMap(widget.pageNumber);

      if (mounted) {
        final processed = _performLineGrouping(data);
        final metadata = _performMetadataDetection(data);

        setState(() {
          _pageData = data;
          _processedLines = processed;
          _lineMetadata = metadata;
          _localImage = localImg;
          _ayahRects = rects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
    _preCacheSurroundingPages();
  }

  Map<int, List<Map<String, dynamic>>> _performLineGrouping(List<Map<String, dynamic>> data) {
    Map<int, List<Map<String, dynamic>>> lines = {};
    for (var verse in data) {
      final words = verse['words'] as List<dynamic>? ?? [];
      for (var word in words) {
        int lineNum = word['line_number'] ?? 1;
        lines.putIfAbsent(lineNum, () => []).add({...word, 'verse_key': verse['verse_key']});
      }
    }
    return lines;
  }

  Map<int, dynamic> _performMetadataDetection(List<Map<String, dynamic>> data) {
    Map<int, dynamic> metadata = {};
    for (int lineIdx = 1; lineIdx <= 15; lineIdx++) {
      for (var verse in data) {
        final vKey = verse['verse_key'] as String;
        final parts = vKey.split(':');
        final sNum = int.parse(parts[0]);
        final ayahNum = int.parse(parts[1]);
        final wordsInVerse = verse['words'] as List<dynamic>? ?? [];
        if (wordsInVerse.isEmpty) continue;
        final firstLineOfAyah = wordsInVerse.first['line_number'] as int? ?? 1;
        if (ayahNum == 1) {
          if (sNum == 1 || sNum == 9) {
            if (lineIdx == firstLineOfAyah - 1) metadata[lineIdx] = {'surah': sNum};
          } else {
            if (lineIdx == firstLineOfAyah - 2) {
              metadata[lineIdx] = {'surah': sNum};
            } else if (lineIdx == firstLineOfAyah - 1) {
              metadata[lineIdx] = {'isBismillah': true};
            }
          }
        }
      }
    }
    return metadata;
  }

  Future<void> _preCacheSurroundingPages() async {
    if (!mounted) return;
    if (widget.pageNumber < 604) {
      _downloadService.getLocalPageImage(widget.pageNumber + 1).then((File? file) {
        if (file != null && mounted) precacheImage(FileImage(file), context);
      });
    }
    if (widget.pageNumber > 1) {
      _downloadService.getLocalPageImage(widget.pageNumber - 1).then((File? file) {
        if (file != null && mounted) precacheImage(FileImage(file), context);
      });
    }
  }

  // ─── Theme Helpers ────────────────────────────────────────────────────────
  Color get _parchmentColor {
    switch (widget.theme) {
      case ThemeService.mushafPremium: return const Color(0xFFFFF8E1);
      case ThemeService.mushafDark: return const Color(0xFF1A1A1A);
      default: return const Color(0xFFFDF5E6);
    }
  }

  Color get _textColor {
    switch (widget.theme) {
      case ThemeService.mushafDark: return const Color(0xFFE8E0D0);
      default: return const Color(0xFF1A1A1A);
    }
  }

  Color get _ornamentColor {
    switch (widget.theme) {
      case ThemeService.mushafDark: return const Color(0xFFD4A947).withValues(alpha: 0.7);
      default: return const Color(0xFFD4A947);
    }
  }

  // ─── Computed Sizes (All scale with fontSize slider) ─────────────────────
  double _uiFontSize(double base) => (base * _fontScaleRatio).clamp(base * 0.7, base * 1.8);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (_pageData.isEmpty) {
      return Center(
        child: Text(
          'تعذر تحميل الصفحة',
          style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 16),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _parchmentColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, spreadRadius: 2)
        ],
      ),
      child: Stack(
        children: [
          // ① Ornate Frame
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PageFramePainter(color: _ornamentColor, edition: widget.edition),
              ),
            ),
          ),

          // ② Main Content (Text + Image)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ── Padding ─────────────────────────────────────────────
                // Top/bottom must clear the header bar and page number footer.
                // Header bar height: ~48px. Footer: ~38px. Frame: ~14px.
                const double topBarH = 50.0;
                const double footerH = 40.0;
                const double frameP = 16.0;
                final double hPadding = constraints.maxWidth * 0.065;
                const double vPaddingTop = topBarH + frameP;
                const double vPaddingBottom = footerH + frameP;

                final double availableWidth = constraints.maxWidth - (hPadding * 2);
                final double availableHeight =
                    constraints.maxHeight - vPaddingTop - vPaddingBottom;
                final double lineHeight = availableHeight / 15;

                return InteractiveViewer(
                  transformationController: _transformationController,
                  onInteractionUpdate: _onInteractionUpdate,
                  minScale: 1.0,
                  maxScale: 4.0,
                  panEnabled: _isZoomed,
                  scaleEnabled: true,
                  boundaryMargin: _isZoomed ? const EdgeInsets.all(300) : EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        hPadding, vPaddingTop, hPadding, vPaddingBottom),
                    child: Stack(
                      children: [
                        // A. Visual Image Layer
                        if (_localImage != null)
                          Positioned.fill(
                            child: Stack(children: [
                              Positioned.fill(
                                child: RepaintBoundary(
                                  child: Image.file(
                                    _localImage!,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.medium,
                                    cacheWidth: (MediaQuery.of(context).size.width *
                                            MediaQuery.of(context).devicePixelRatio)
                                        .toInt(),
                                  ),
                                ),
                              ),
                              _buildImageInteractions(
                                  Size(availableWidth, availableHeight)),
                            ]),
                          ),

                        // B. Text + Interactive Layer
                        IgnorePointer(
                          ignoring: _localImage != null &&
                              _ayahRects.isNotEmpty &&
                              !showDebugBoxes,
                          child: SizedBox(
                            width: availableWidth,
                            height: availableHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(15, (index) {
                                int lineIdx = index + 1;
                                List<Map<String, dynamic>> lineWords =
                                    _processedLines[lineIdx] ?? [];
                                final meta = _lineMetadata[lineIdx];
                                int? headerForSurah = meta?['surah'];
                                bool isBismillah = meta?['isBismillah'] ?? false;

                                Widget lineWidget;
                                if (headerForSurah != null) {
                                  lineWidget = _localImage != null
                                      ? const SizedBox.shrink()
                                      : _buildSurahHeader(
                                          QuranPageHelper.surahNames[headerForSurah - 1],
                                          availableWidth,
                                          lineHeight);
                                } else if (isBismillah) {
                                  lineWidget = _localImage != null
                                      ? const SizedBox.shrink()
                                      : _buildBismillah(availableWidth, lineHeight);
                                } else {
                                  lineWidget = _buildLine(
                                    lineWords,
                                    availableWidth,
                                    lineHeight,
                                    isLastLine: index == 14,
                                    isTransparent: _localImage != null,
                                  );
                                }
                                return SizedBox(height: lineHeight, child: lineWidget);
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ③ Top Info Bar (اسم السورة / رقم الجزء)
          Positioned(
            top: 14,
            left: 50,
            right: 50,
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _buildTopInfo(isLeft: true)),
                const SizedBox(width: 8),
                Flexible(child: _buildTopInfo(isLeft: false)),
              ],
            ),
          ),

          // ④ Page Number Footer
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(child: _buildPageFooter()),
          ),
        ],
      ),
    );
  }

  // ─── Top Info (Surah name / Juz) ─────────────────────────────────────────
  Widget _buildTopInfo({required bool isLeft}) {
    final surahName = QuranPageHelper.getSurahNameForPage(widget.pageNumber);
    final juzNumber = QuranPageHelper.getJuzForPage(widget.pageNumber);
    final text = isLeft ? 'جزء $juzNumber' : surahName;
    // UI info uses a fixed small size — only slightly scales with font pref
    final double uiSize = _uiFontSize(12.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _ornamentColor.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(10),
        color: _parchmentColor.withValues(alpha: 0.85),
      ),
      child: Text(
        text,
        style: getArabicTextStyle(
          fontFamily: widget.fontFamily,
          fontSize: uiSize,
          color: _textColor.withValues(alpha: 0.8),
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // ─── Surah Header ─────────────────────────────────────────────────────────
  Widget _buildSurahHeader(String name, double availableWidth, double lineHeight) {
    final double safeFontSize = min(availableWidth * 0.055, lineHeight * 0.72);
    final double headerFontSize = min(safeFontSize * _fontScaleRatio, 44.0);
    return SizedBox(
      width: availableWidth,
      height: lineHeight,
      child: CustomPaint(
        painter: _SurahHeaderPainter(color: _ornamentColor, edition: widget.edition),
        child: Center(
          child: Text(
            'سُورَةُ $name',
            style: getArabicTextStyle(
              fontFamily: widget.fontFamily,
              fontSize: headerFontSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ─── Bismillah ────────────────────────────────────────────────────────────
  Widget _buildBismillah(double availableWidth, double lineHeight) {
    final double safeFontSize = min(availableWidth * 0.055, lineHeight * 0.68);
    final double bismFontSize = min(safeFontSize * _fontScaleRatio, 40.0);
    return Container(
      width: availableWidth,
      height: lineHeight,
      alignment: Alignment.center,
      child: Text(
        'بِسْمِ ٱللّٰهِ الرَّحْمٰنِ الرَّحِيمِ',
        style: getArabicTextStyle(
          fontFamily: widget.fontFamily,
          fontSize: bismFontSize,
          color: _textColor,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }

  // ─── Page Footer ──────────────────────────────────────────────────────────
  Widget _buildPageFooter() {
    final double footerFontSize = _uiFontSize(13.0);
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(footerFontSize * 3.2, footerFontSize * 3.2),
          painter: _FooterOrnamentPainter(color: _ornamentColor),
        ),
        Text(
          '${widget.pageNumber}',
          style: GoogleFonts.amiri(
            fontSize: footerFontSize,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  // ─── Main Line Builder ────────────────────────────────────────────────────
  Widget _buildLine(
    List<Map<String, dynamic>> words,
    double availableWidth,
    double lineHeight, {
    bool isLastLine = false,
    bool isTransparent = false,
  }) {
    if (words.isEmpty) return const SizedBox.shrink();

    final bool shouldJustify = words.length > 2 && !isLastLine;

    // ── Core Font Size Formula ──────────────────────────────────────────────
    // To ensure uniform fonts, base the core size on available width so it rarely needs to shrink
    final double safeSize = min(availableWidth * 0.054, lineHeight * 0.72);
    final double coreFontSize =
        (safeSize * _fontScaleRatio).clamp(lineHeight * 0.35, lineHeight * 0.85);

    return Container(
      width: availableWidth,
      height: lineHeight,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: shouldJustify ? availableWidth : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                shouldJustify ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: words.map((w) {
              final verseKey = w['verse_key'] as String;
              final parts = verseKey.split(':');
              final sNum = int.parse(parts[0]);
              final ayahNum = int.parse(parts[1]);

              bool isAyahActive = widget.highlightedSurah == sNum && widget.highlightedAyah == ayahNum;
              bool isWordActive = widget.highlightedWordLocation != null && w['location'] == widget.highlightedWordLocation;
              
              // 🚀 If Audio is playing (WordLocation is not null), only highlight the exact word.
              // Otherwise, highlight the entire selected Ayah.
              bool isHighlighted = widget.highlightedWordLocation != null ? isWordActive : isAyahActive;
              final bool isEnd =
                  w['is_last_word'] == true || _isLastWordOfVerse(w, words);

              String cleanText = w['text_uthmani'] ?? '';
              cleanText = cleanText
                  .replaceAll(RegExp(r'[\u06DD\uFD3E\uFD3F0-9\u0660-\u0669]'), '')
                  .trim();

              final Color wordColor =
                  isTransparent ? Colors.transparent : _textColor;
              final TextStyle wordStyle = getArabicTextStyle(
                fontFamily: widget.fontFamily,
                fontSize: coreFontSize,
                color: wordColor,
                fontWeight: FontWeight.w500,
                height: 1.3,
              );
              final TextStyle tajweedBaseStyle = getArabicTextStyle(
                fontFamily: widget.fontFamily,
                fontSize: coreFontSize,
                color: wordColor,
                fontWeight: FontWeight.w500,
                height: 1.3,
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onAyahTapped?.call(sNum, ayahNum),
                    onLongPress: () => widget.onAyahLongPressed?.call(sNum, ayahNum),
                    child: AnimatedBuilder(
                      animation: _auraController,
                      builder: (context, child) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppColors.gold
                                  .withValues(alpha: 0.15 + (0.08 * _auraController.value))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isHighlighted
                              ? [
                                  BoxShadow(
                                    color: AppColors.gold
                                        .withValues(alpha: 0.12 * _auraController.value),
                                    blurRadius: 8 * _auraController.value,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: child,
                      ),
                      child: Opacity(
                        opacity: (widget.isMemorizationMode && isHighlighted) ? 0.15 : 1.0,
                        child: widget.showTajweed && w['text_tajweed'] != null
                            ? RichText(
                                textDirection: TextDirection.rtl,
                                text: TextSpan(
                                  children: TajweedParser.parse(
                                      w['text_tajweed']!, tajweedBaseStyle),
                                ),
                              )
                            : Text(cleanText, style: wordStyle),
                      ),
                    ),
                  ),
                  if (isEnd) ...[
                    const SizedBox(width: 3),
                    _buildAyahEndMark(ayahNum, lineHeight),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  bool _isLastWordOfVerse(
      Map<String, dynamic> currentWord, List<Map<String, dynamic>> allLineWords) {
    final idx = allLineWords.indexOf(currentWord);
    if (idx < allLineWords.length - 1) {
      return currentWord['verse_key'] != allLineWords[idx + 1]['verse_key'];
    }
    for (var verse in _pageData) {
      if (verse['verse_key'] == currentWord['verse_key']) {
        final words = verse['words'] as List<dynamic>? ?? [];
        if (words.isNotEmpty && words.last['position'] == currentWord['position']) {
          return true;
        }
      }
    }
    return false;
  }

  // ─── Ayah End Mark ────────────────────────────────────────────────────────
  // Size scales with the font, clamped to stay proportional.
  Widget _buildAyahEndMark(int number, double lineHeight) {
    final double markSize =
        (lineHeight * 0.75 * _fontScaleRatio).clamp(lineHeight * 0.45, lineHeight * 0.90);
    final double numFontSize = (markSize * 0.45).clamp(8.0, 26.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(markSize, markSize),
          painter: _AyahEndPainter(color: _ornamentColor),
        ),
        Text(
          '$number',
          style: GoogleFonts.amiri(
            fontSize: numFontSize,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  // ─── Image Interactions ───────────────────────────────────────────────────
  Widget _buildImageInteractions(Size viewSize) {
    if (_ayahRects.isEmpty) return const SizedBox.shrink();
    const Size designSize = Size(1100, 1570);
    double viewAspectRatio = viewSize.width / viewSize.height;
    double designAspectRatio = designSize.width / designSize.height;
    double actualWidth, actualHeight, offsetX, offsetY;
    if (viewAspectRatio > designAspectRatio) {
      actualHeight = viewSize.height;
      actualWidth = actualHeight * designAspectRatio;
      offsetX = (viewSize.width - actualWidth) / 2;
      offsetY = 0;
    } else {
      actualWidth = viewSize.width;
      actualHeight = actualWidth / designAspectRatio;
      offsetY = (viewSize.height - actualHeight) / 2;
      offsetX = 0;
    }
    final double scaleX = actualWidth / designSize.width;
    final double scaleY = actualHeight / designSize.height;

    return Stack(
      children: _ayahRects.entries.map((entry) {
        final key = entry.key;
        final rects = entry.value;
        final parts = key.split(':');
        final sNum = int.parse(parts[0]);
        final aNum = int.parse(parts[1]);
        bool isHighlighted = widget.highlightedSurah == sNum && widget.highlightedAyah == aNum;

        final List<dynamic> verseWords = _pageData.firstWhere(
          (v) => v['verse_key'] == key,
          orElse: () => {'words': []},
        )['words'] ?? [];

        return Stack(
          children: rects.map((r) {
            final int glyphIdx = rects.indexOf(r);
            String? glyphLocation;
            if (glyphIdx < verseWords.length) {
              glyphLocation = verseWords[glyphIdx]['location'];
            }
            bool isWordHighlighted = widget.highlightedWordLocation != null &&
                glyphLocation == widget.highlightedWordLocation;

            final scaledRect = Rect.fromLTRB(
              offsetX + (r.left * scaleX),
              offsetY + (r.top * scaleY),
              offsetX + (r.right * scaleX),
              offsetY + (r.bottom * scaleY),
            );

            return Positioned.fromRect(
              rect: scaledRect,
              child: GestureDetector(
                onTap: () => widget.onAyahTapped?.call(sNum, aNum),
                onLongPress: () => widget.onAyahLongPressed?.call(sNum, aNum),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: showDebugBoxes
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : (isWordHighlighted
                            ? AppColors.gold.withValues(alpha: 0.45)
                            : (isHighlighted
                                ? AppColors.gold.withValues(alpha: 0.22)
                                : Colors.transparent)),
                    borderRadius: BorderRadius.circular(2),
                    border: showDebugBoxes
                        ? Border.all(color: Colors.red, width: 1.0)
                        : null,
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ============================================================
//  ORNAMENTAL PAINTERS
// ============================================================

class _PageFramePainter extends CustomPainter {
  final Color color;
  final String edition;
  _PageFramePainter({required this.color, required this.edition});

  @override
  void paint(Canvas canvas, Size size) {
    final bool is1422 = edition == ThemeService.editionMadina1422;
    final bool isWarsh = edition == ThemeService.editionWarsh;
    const double p = 14.0;
    const double p2 = 22.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final mainRect = Rect.fromLTRB(p, p, size.width - p, size.height - p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(mainRect, const Radius.circular(4)), shadowPaint);

    final framePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.8), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(mainRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = is1422 ? 3.5 : 2.5;
    canvas.drawRect(mainRect, framePaint);

    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(
        Rect.fromLTRB(p2, p2, size.width - p2, size.height - p2), innerPaint);

    final accentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = is1422 ? 4.0 : 3.0;
    final cornerSize = isWarsh ? 70.0 : 55.0;
    _drawPremiumCorner(canvas, const Offset(p, p), cornerSize, accentPaint,
        isTop: true, isLeft: true);
    _drawPremiumCorner(canvas, Offset(size.width - p, p), cornerSize, accentPaint,
        isTop: true, isLeft: false);
    _drawPremiumCorner(canvas, Offset(p, size.height - p), cornerSize, accentPaint,
        isTop: false, isLeft: true);
    _drawPremiumCorner(canvas, Offset(size.width - p, size.height - p), cornerSize,
        accentPaint, isTop: false, isLeft: false);
  }

  void _drawPremiumCorner(Canvas canvas, Offset origin, double size, Paint paint,
      {required bool isTop, required bool isLeft}) {
    final double sx = isLeft ? 1 : -1;
    final double sy = isTop ? 1 : -1;
    final path = Path()
      ..moveTo(origin.dx, origin.dy + size * sy)
      ..quadraticBezierTo(origin.dx, origin.dy, origin.dx + size * sx, origin.dy);
    if (edition == ThemeService.editionMadina1405 ||
        edition == ThemeService.editionMadina1422) {
      path.moveTo(origin.dx + (size * 0.3 * sx), origin.dy);
      path.quadraticBezierTo(
          origin.dx + (size * 0.5 * sx),
          origin.dy + (size * 0.2 * sy),
          origin.dx + (size * 0.3 * sx),
          origin.dy + (size * 0.4 * sy));
      path.quadraticBezierTo(
          origin.dx + (size * 0.1 * sx),
          origin.dy + (size * 0.2 * sy),
          origin.dx + (size * 0.3 * sx),
          origin.dy);
    }
    canvas.drawPath(path, paint);
    if (edition == ThemeService.editionMadina1422) {
      _draw8PointStar(canvas, origin, paint);
    } else {
      final dPaint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(origin.dx + (8 * sx), origin.dy + (8 * sy)), 4, dPaint);
    }
  }

  void _draw8PointStar(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    const double radius = 12.0;
    for (int i = 0; i < 8; i++) {
      final double angle = (i * 45) * pi / 180;
      final double r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _PageFramePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.edition != edition;
}

class _SurahHeaderPainter extends CustomPainter {
  final Color color;
  final String edition;
  _SurahHeaderPainter({required this.color, required this.edition});

  @override
  void paint(Canvas canvas, Size size) {
    final bool is1422 = edition == ThemeService.editionMadina1422;
    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          is1422 ? const Color(0xFF0D47A1) : const Color(0xFF00695C),
          is1422 ? const Color(0xFF1976D2) : const Color(0xFF00897B),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, framePaint);

    final wingPaint = Paint()..color = color..style = PaintingStyle.fill;
    final wingPath = Path();
    wingPath.moveTo(0, size.height * 0.2);
    wingPath.quadraticBezierTo(-18, size.height / 2, 0, size.height * 0.8);
    wingPath.moveTo(size.width, size.height * 0.2);
    wingPath.quadraticBezierTo(size.width + 18, size.height / 2, size.width, size.height * 0.8);
    canvas.drawPath(wingPath, wingPaint);

    canvas.drawRRect(rrect.deflate(4), framePaint..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant _SurahHeaderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.edition != edition;
}

class _AyahEndPainter extends CustomPainter {
  final Color color;
  _AyahEndPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.1;

    final path = Path();
    for (int i = 0; i < 16; i++) {
      double angle = (i * 22.5) * pi / 180;
      double r = i.isEven ? radius : radius * 0.7;
      if (i == 0) {
        path.moveTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      } else {
        path.lineTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      }
    }
    path.close();
    canvas.drawPath(
        path, Paint()..color = color.withValues(alpha: 0.12)..style = PaintingStyle.fill);
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, radius * 0.6, paint..strokeWidth = 1.0);
    canvas.drawCircle(center, radius * 0.45, paint..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant _AyahEndPainter oldDelegate) => oldDelegate.color != color;
}

class _FooterOrnamentPainter extends CustomPainter {
  final Color color;
  _FooterOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final path = Path();
    const int petals = 32;
    for (int i = 0; i < petals; i++) {
      double angle = (i * 360 / petals) * pi / 180;
      double r = (i % 2 == 0) ? size.width / 2.2 : size.width / 2.5;
      if (i == 0) {
        path.moveTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      } else {
        path.lineTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      }
    }
    path.close();
    canvas.drawPath(path, mainPaint);
    canvas.drawCircle(center, size.width / 2.7, mainPaint..strokeWidth = 0.8);

    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * pi / 180;
      canvas.drawCircle(
        Offset(center.dx + (size.width / 2) * cos(angle),
            center.dy + (size.width / 2) * sin(angle)),
        1.5,
        Paint()..color = color..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FooterOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
