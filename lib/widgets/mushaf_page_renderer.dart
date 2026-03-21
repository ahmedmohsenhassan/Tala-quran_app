import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_text_service.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../services/download_service.dart';
import 'dart:io';
import '../services/ayah_info_service.dart'; // 🎯 New for Phase 63

class MushafPageRenderer extends StatefulWidget {
  final int pageNumber;
  final Function(int surah, int ayah)? onAyahTapped;
  final int? highlightedAyah;
  final int? highlightedSurah;
  final bool isMemorizationMode;
  final String theme;
  final double fontSize;
  final String fontFamily;
  final String edition;
  final String? highlightedWordLocation; // 🎙️ For word-by-word sync
  final PageController? pageController;

  const MushafPageRenderer({
    super.key,
    required this.pageNumber,
    this.onAyahTapped,
    this.highlightedAyah,
    this.highlightedSurah,
    this.isMemorizationMode = false,
    this.theme = ThemeService.mushafClassic,
    this.fontSize = 24.0,
    this.fontFamily = ThemeService.fontAmiri,
    this.edition = ThemeService.editionMadina1405,
    this.highlightedWordLocation,
    this.pageController,
  });

  @override
  State<MushafPageRenderer> createState() => _MushafPageRendererState();
}

class _MushafPageRendererState extends State<MushafPageRenderer> {
  final QuranTextService _quranService = QuranTextService();
  List<Map<String, dynamic>> _pageData = [];
  bool _isLoading = true;
  late TransformationController _transformationController;
  bool _isZoomed = false;
  File? _localImage;
  final DownloadService _downloadService = DownloadService();
  final AyahInfoService _ayahInfoService = AyahInfoService();
  Map<String, List<Rect>> _ayahRects = {};
  bool _isDownloading = false; // 📥 New for Phase 64

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _loadPageData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final double scale = _transformationController.value.getMaxScaleOnAxis();
    if (mounted) {
      if (scale > 1.05 && !_isZoomed) {
        setState(() => _isZoomed = true);
      } else if (scale <= 1.05 && _isZoomed) {
        setState(() => _isZoomed = false);
      }
    }
  }

  @override
  void didUpdateWidget(MushafPageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
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
        debugPrint('📖 Page ${widget.pageNumber}: Words=${data.length}, Rects=${rects.length}, Image=${localImg != null}');
        setState(() {
          _pageData = data;
          _localImage = localImg;
          _ayahRects = rects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color get _parchmentColor {
    switch (widget.theme) {
      case ThemeService.mushafPremium: return const Color(0xFFFFF8E1);
      case ThemeService.mushafDark: return const Color(0xFF1E1E1E);
      default: return const Color(0xFFFDF5E6);
    }
  }

  Color get _textColor {
    switch (widget.theme) {
      case ThemeService.mushafDark: return const Color(0xFFE0E0E0);
      default: return const Color(0xFF1A1A1A);
    }
  }

  Color get _ornamentColor {
    switch (widget.theme) {
      case ThemeService.mushafDark: return const Color(0xFFD4A947).withValues(alpha: 0.6);
      default: return const Color(0xFFD4A947);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (_pageData.isEmpty) {
      return Center(
        child: Text(
          'تعذر تحميل الصفحة المستندة للنصوص',
          style: GoogleFonts.amiri(
            color: AppColors.textMuted,
            fontSize: 16,
          ),
        ),
      );
    }

    // Group all words on the page by line number
    Map<int, List<Map<String, dynamic>>> lines = {};
    for (var verse in _pageData) {
      final words = verse['words'] as List<dynamic>? ?? [];
      for (var word in words) {
        int lineNum = word['line_number'] ?? 1;
        lines.putIfAbsent(lineNum, () => []).add({...word, 'verse_key': verse['verse_key']});
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _parchmentColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Stack(
        children: [
          // 1. Ornate Frame (Always below text)
          Positioned.fill(
            child: CustomPaint(
              painter: _PageFramePainter(
                color: _ornamentColor,
                edition: widget.edition,
              ),
            ),
          ),
          
          // 2. Interactive Main Content (Image or Text + Interactive Layer)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  onInteractionUpdate: _onInteractionUpdate,
                  minScale: 1.0,
                  maxScale: 4.0,
                  panEnabled: _isZoomed,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      // A. Visual Layer (Local Image or Fallback Text)
                      if (_localImage != null)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, imgConstraints) {
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      _localImage!,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                  // 🎯 Interactivity Layer for Image mode
                                  _buildImageInteractions(imgConstraints.biggest),
                                ],
                              );
                            },
                          ),
                        ),
                      
                      // B. Interactive Layer (Visible if no image, Transparent if image exists)
                      IgnorePointer(
                        ignoring: _localImage != null && _ayahRects.isNotEmpty,
                        child: Container(
                          width: 420,
                          height: 720,
                          padding: EdgeInsets.zero,
                          color: _localImage != null ? Colors.transparent : null,
                          child: Column(
                            children: List.generate(15, (index) {
                              int lineIdx = index + 1;
                              List<Map<String, dynamic>> lineWords = lines[lineIdx] ?? [];
                              
                              int? headerForSurah;
                              bool isBismillah = false;
                              
                              for (var verse in _pageData) {
                                final vKey = verse['verse_key'] as String;
                                final parts = vKey.split(':');
                                final sNum = int.parse(parts[0]);
                                final ayahNum = int.parse(parts[1]);
                                
                                final wordsInVerse = verse['words'] as List<dynamic>? ?? [];
                                if (wordsInVerse.isEmpty) continue;
                                final firstLineOfAyah = wordsInVerse.first['line_number'] as int? ?? 1;
                                
                                if (ayahNum == 1) {
                                  if (sNum == 1 || sNum == 9) {
                                    if (lineIdx == firstLineOfAyah - 1) {
                                      headerForSurah = sNum;
                                    }
                                  } else {
                                    if (lineIdx == firstLineOfAyah - 2) {
                                      headerForSurah = sNum;
                                    } else if (lineIdx == firstLineOfAyah - 1) {
                                      isBismillah = true;
                                    }
                                  }
                                }
                              }
  
                              Widget lineWidget;
                              if (headerForSurah != null) {
                                lineWidget = _localImage != null 
                                  ? const SizedBox.shrink() 
                                  : _buildSurahHeader(QuranPageHelper.surahNames[headerForSurah - 1]);
                              } else if (isBismillah) {
                                lineWidget = _localImage != null
                                  ? const SizedBox.shrink()
                                  : _buildBismillah();
                              } else {
                                lineWidget = _buildLine(lineWords, isTransparent: _localImage != null);
                              }
  
                              return SizedBox(
                                height: 48,
                                child: lineWidget,
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Page Number Footer
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: _buildPageFooter(),
            ),
          ),

          // 5. Download Prompt (Overlay)
          if (_localImage == null)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isDownloading ? null : () async {
                    setState(() => _isDownloading = true);
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('بدء تحميل الصفحة...'))
                      );
                      await _downloadService.downloadPage(widget.pageNumber);
                      
                      // 🔄 Periodic check for download completion
                      int checks = 0;
                      Timer.periodic(const Duration(seconds: 2), (timer) async {
                        checks++;
                        final file = await _downloadService.getLocalPageImage(widget.pageNumber);
                        if (file != null || checks > 15) {
                          timer.cancel();
                          if (mounted) {
                            setState(() => _isDownloading = false);
                            _loadPageData(); 
                          }
                        }
                      });
                    } catch (e) {
                      if (mounted) setState(() => _isDownloading = false);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isDownloading ? Colors.grey : AppColors.gold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isDownloading ? Icons.hourglass_empty_rounded : Icons.download_rounded, 
                          color: Colors.white, 
                          size: 20
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isDownloading ? 'جاري التحميل...' : 'تحميل الصفحة (KFGQPC)',
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 35,
            left: 50,
            right: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTopInfo(isLeft: true),
                _buildTopInfo(isLeft: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfo({required bool isLeft}) {
    final surahName = QuranPageHelper.getSurahNameForPage(widget.pageNumber);
    final juzNumber = QuranPageHelper.getJuzForPage(widget.pageNumber);
    final text = isLeft ? 'جزء $juzNumber' : surahName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _ornamentColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: widget.fontFamily == ThemeService.fontAmiri
          ? GoogleFonts.amiri(
              fontSize: 14 * (widget.fontSize / 24.0),
              fontWeight: FontWeight.bold,
              color: _textColor.withValues(alpha: 0.7),
            )
          : TextStyle(
              fontFamily: widget.fontFamily,
              fontSize: 14 * (widget.fontSize / 24.0),
              fontWeight: FontWeight.bold,
              color: _textColor.withValues(alpha: 0.7),
            ),
      ),
    );
  }

  Widget _buildSurahHeader(String name) {
    return SizedBox(
      width: double.infinity,
      height: 48, // Must fit exactly 1 line of the 15-line grid
      child: CustomPaint(
        painter: _SurahHeaderPainter(
          color: _ornamentColor,
          edition: widget.edition,
        ),
        child: Center(
          child: Text(
            "سُورَةُ $name",
            style: GoogleFonts.amiri(
              fontSize: 32, // LARGER FONT AS REQUESTED
              fontWeight: FontWeight.bold,
              color: _textColor,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildBismillah() {
    return Container(
      height: 48,
      alignment: Alignment.center,
      child: Text(
        "بِسْمِ ٱللّٰهِ الرَّحْمٰنِ الرَّحِيمِ",
        style: GoogleFonts.amiri(
          fontSize: 28, // LARGER FONT AS REQUESTED
          fontWeight: FontWeight.w500,
          color: _textColor,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildPageFooter() {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(45, 45),
          painter: _FooterOrnamentPainter(color: _ornamentColor),
        ),
        Text(
          "${widget.pageNumber}",
          style: GoogleFonts.amiri(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(List<Map<String, dynamic>> words, {bool isTransparent = false}) {
    if (words.isEmpty) return const SizedBox.shrink();

    // Justification: Spreads words to fill 100% of the line width
    // except for lines that end a paragraph/page (optional heuristic)
    final bool shouldJustify = words.length > 2;

    return Container(
      width: 420, // Match the outer container width
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight, // Maintain RTL feel
        child: Container(
          width: 420, // Force the FittedBox to think the child is this wide
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: shouldJustify ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            textDirection: TextDirection.rtl,
            children: words.map((w) {
              final verseKey = w['verse_key'] as String;
              final parts = verseKey.split(':');
              final sNum = int.parse(parts[0]);
              final ayahNum = int.parse(parts[1]);

              bool isHighlighted = widget.highlightedSurah == sNum && widget.highlightedAyah == ayahNum;
              final bool isEnd = w['is_last_word'] == true || _isLastWordOfVerse(w, words);

              // DETECT & REMOVE REPEATED AYAH END SYMBOLS FROM FONT
              String cleanText = w['text_uthmani'] ?? "";
              // Remove the character \u06DD (End of Ayah) if present in font data
              // Also common to have \uFD3E \uFD3F (Ornate Parentheses) for numbers
              cleanText = cleanText.replaceAll(RegExp(r'[\u06DD\uFD3E\uFD3F0-9\u0660-\u0669]'), '').trim();

              return Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.rtl,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque, // 🎯 Ensure it captures taps even if child is transparent
                    onTap: () {
                      if (widget.onAyahTapped != null) {
                        widget.onAyahTapped!(sNum, ayahNum);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isHighlighted ? AppColors.gold.withValues(alpha: 0.22) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Opacity(
                        opacity: (widget.isMemorizationMode && isHighlighted) ? 0.2 : 1.0,
                        child: Text(
                          cleanText,
                          style: widget.fontFamily == ThemeService.fontAmiri 
                            ? GoogleFonts.amiri(
                                fontSize: widget.fontSize, 
                                color: isTransparent ? Colors.transparent : _textColor,
                                fontWeight: FontWeight.w500,
                                height: 1.1,
                              )
                            : TextStyle(
                                fontFamily: widget.fontFamily,
                                fontStyle: FontStyle.normal, // Ensure no italics from serifs
                                fontSize: widget.fontSize,
                                color: isTransparent ? Colors.transparent : _textColor,
                                height: 1.1,
                              ),
                        ),
                      ),
                    ),
                  ),
                  if (isEnd) ...[
                    const SizedBox(width: 4),
                    _buildAyahEndMark(ayahNum),
                  ],
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  bool _isLastWordOfVerse(Map<String, dynamic> currentWord, List<Map<String, dynamic>> allLineWords) {
    // 1. Check if the next word on the same line belongs to a different verse
    final idx = allLineWords.indexOf(currentWord);
    if (idx < allLineWords.length - 1) {
      final nextWord = allLineWords[idx + 1];
      return currentWord['verse_key'] != nextWord['verse_key'];
    }

    // 2. If it's the last word on the line, check if it's the last word of its verse in _pageData
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

  Widget _buildAyahEndMark(int number) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(28, 28),
          painter: _AyahEndPainter(color: _ornamentColor),
        ),
        Text(
          "$number",
          style: GoogleFonts.amiri(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  /// 📐 الإحداثيات الذكية — Smart Coordinate Mapping
  Widget _buildImageInteractions(Size viewSize) {
    if (_ayahRects.isEmpty) return const SizedBox.shrink();

    // Design size of the KFGQPC coordinates (Typical 1100x1570 or 1260x1800)
    // We assume 1100x1570 for these DBs, but let's make it detectable or standard
    const Size designSize = Size(1100, 1570); 

    // Calculate actual image rect within the BoxFit.contain view
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
        final key = entry.key; // "surah:ayah"
        final rects = entry.value;
        final parts = key.split(':');
        final sNum = int.parse(parts[0]);
        final aNum = int.parse(parts[1]);

        bool isHighlighted = widget.highlightedSurah == sNum && widget.highlightedAyah == aNum;

        // 🎯 Word-by-Word data logic
        final List<dynamic> verseWords = _pageData.firstWhere(
          (v) => v['verse_key'] == key,
          orElse: () => {'words': []},
        )['words'] ?? [];

        return Stack(
          children: rects.map((r) {
            // Find if this specific glyph/rect belongs to a word or end mark
            final int glyphIdx = rects.indexOf(r);
            String? glyphLocation;
            
            // Heuristic: mapping glyphs to words (simplified for now)
            if (glyphIdx < verseWords.length) {
              glyphLocation = verseWords[glyphIdx]['location'];
            }

            bool isWordHighlighted = widget.highlightedWordLocation != null && 
                                   glyphLocation == widget.highlightedWordLocation;

            // Apply scale and offset to the design rect
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
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150), // FASTER for words
                  decoration: BoxDecoration(
                    color: isWordHighlighted
                        ? AppColors.gold.withValues(alpha: 0.45) // DARKER for specific word
                        : (isHighlighted ? AppColors.gold.withValues(alpha: 0.2) : Colors.transparent),
                    borderRadius: BorderRadius.circular(2),
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

    // 1. Shadow Layer for Depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final mainRect = Rect.fromLTRB(p, p, size.width - p, size.height - p);
    canvas.drawRRect(RRect.fromRectAndRadius(mainRect, const Radius.circular(4)), shadowPaint);

    // 2. Main Golden Frame
    final framePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.8), color, color.withValues(alpha: 1.2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(mainRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = is1422 ? 3.5 : 2.5;

    canvas.drawRect(mainRect, framePaint);
    
    // Inner Decorative Line
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(Rect.fromLTRB(p2, p2, size.width - p2, size.height - p2), innerPaint);

    // 3. Intricate Corners (Premium Style)
    final accentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = is1422 ? 4.0 : 3.0;

    final cornerSize = isWarsh ? 70.0 : 55.0;
    
    _drawPremiumCorner(canvas, const Offset(p, p), cornerSize, accentPaint, isTop: true, isLeft: true);
    _drawPremiumCorner(canvas, Offset(size.width - p, p), cornerSize, accentPaint, isTop: true, isLeft: false);
    _drawPremiumCorner(canvas, Offset(p, size.height - p), cornerSize, accentPaint, isTop: false, isLeft: true);
    _drawPremiumCorner(canvas, Offset(size.width - p, size.height - p), cornerSize, accentPaint, isTop: false, isLeft: false);
  }

  void _drawPremiumCorner(Canvas canvas, Offset origin, double size, Paint paint, {required bool isTop, required bool isLeft}) {
    final double sx = isLeft ? 1 : -1;
    final double sy = isTop ? 1 : -1;
    
    // Floral Flourish Path
    final path = Path()
      ..moveTo(origin.dx, origin.dy + size * sy)
      ..quadraticBezierTo(origin.dx, origin.dy, origin.dx + size * sx, origin.dy);
    
    // Add "Floral Petal" for 1405/1422
    if (edition != ThemeService.editionWarsh) {
      path.moveTo(origin.dx + (size * 0.3 * sx), origin.dy);
      path.quadraticBezierTo(origin.dx + (size * 0.5 * sx), origin.dy + (size * 0.2 * sy), origin.dx + (size * 0.3 * sx), origin.dy + (size * 0.4 * sy));
      path.quadraticBezierTo(origin.dx + (size * 0.1 * sx), origin.dy + (size * 0.2 * sy), origin.dx + (size * 0.3 * sx), origin.dy);
    }
      
    canvas.drawPath(path, paint);

    // Ornament Motifs
    if (edition == ThemeService.editionMadina1422) {
      _draw8PointStar(canvas, origin, paint);
    } else {
      // Moroccan Warsh or 1405 Diamond
      final dPaint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(origin.dx + (8 * sx), origin.dy + (8 * sy)), 4, dPaint);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SurahHeaderPainter extends CustomPainter {
  final Color color; // Theme Gold/Green
  final String edition;
  _SurahHeaderPainter({required this.color, required this.edition});

  @override
  void paint(Canvas canvas, Size size) {
    final bool is1422 = edition == ThemeService.editionMadina1422;
    
    final framePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Premium "Plate" Background (Madina Blue/Cyan tone for headers)
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          is1422 ? const Color(0xFF0D47A1) : const Color(0xFF00695C), 
          is1422 ? const Color(0xFF1976D2) : const Color(0xFF00897B)
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    
    // 1. Draw Plate
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, framePaint);
    
    // 2. Draw Side "Wings" (The characteristic Mushaf header ears)
    final wingPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final wingPath = Path();
    // Left Wing
    wingPath.moveTo(0, size.height * 0.2);
    wingPath.quadraticBezierTo(-20, size.height/2, 0, size.height * 0.8);
    // Right Wing
    wingPath.moveTo(size.width, size.height * 0.2);
    wingPath.quadraticBezierTo(size.width + 20, size.height/2, size.width, size.height * 0.8);
    
    canvas.drawPath(wingPath, wingPaint);
    
    // 3. Inner Gold Borders
    canvas.drawRRect(rrect.deflate(4), framePaint..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AyahEndPainter extends CustomPainter {
  final Color color;
  _AyahEndPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
      
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width / 2.1;

    // Geometric Star
    final path = Path();
    for (int i = 0; i < 16; i++) {
      double angle = (i * 22.5) * pi / 180;
      double r = (i.isEven) ? radius : radius * 0.7;
      if (i == 0) {
        path.moveTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      } else {
        path.lineTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      }
    }
    path.close();
    
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill);
    canvas.drawPath(path, paint);
    
    // Double circle for number
    canvas.drawCircle(center, radius * 0.6, paint..strokeWidth = 1.0);
    canvas.drawCircle(center, radius * 0.45, paint..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FooterOrnamentPainter extends CustomPainter {
  final Color color;
  _FooterOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Islamic Medallion Shape
    final path = Path();
    const int petals = 32;
    for (int i = 0; i < petals; i++) {
       double angle = (i * 360 / petals) * pi / 180;
       double r = (i % 2 == 0) ? size.width/2.2 : size.width/2.4;
       if (i == 0) {
         path.moveTo(center.dx + r*cos(angle), center.dy + r*sin(angle));
       } else {
         path.lineTo(center.dx + r*cos(angle), center.dy + r*sin(angle));
       }
    }
    path.close();
    
    canvas.drawPath(path, mainPaint);
    canvas.drawCircle(center, size.width/2.6, mainPaint..strokeWidth = 1.0);
    
    // Dots
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * pi / 180;
      canvas.drawCircle(Offset(center.dx + (size.width/2) * cos(angle), center.dy + (size.width/2) * sin(angle)), 1.5, Paint()..color = color..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
