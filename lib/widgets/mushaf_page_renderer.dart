import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_text_service.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';

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
      if (mounted) {
        setState(() {
          _pageData = data;
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
          style: GoogleFonts.amiri(color: AppColors.textMuted),
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
              painter: _PageFramePainter(color: _ornamentColor),
            ),
          ),
          
          // 2. Interactive Main Text Content (Zoom & Pan support)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  onInteractionUpdate: _onInteractionUpdate,
                  minScale: 1.0,
                  maxScale: 4.0,
                  panEnabled: _isZoomed, // Only pan if zoomed in
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth - 80,
                      minHeight: constraints.maxHeight - 120,
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 420,
                          height: 750,
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
                                lineWidget = _buildSurahHeader(QuranPageHelper.surahNames[headerForSurah - 1]);
                              } else if (isBismillah) {
                                lineWidget = _buildBismillah();
                              } else {
                                lineWidget = _buildLine(lineWords);
                              }

                              return Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.center,
                                  child: lineWidget,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
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

          // 4. Top Header (Juz & Surah Name)
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
    return Container(
      height: 60, // Fixed height for header line in the 15-line grid
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      child: CustomPaint(
        painter: _SurahHeaderPainter(color: _ornamentColor),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
            child: Text(
              "سُورَةُ $name",
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
                shadows: [
                  Shadow(
                    color: _ornamentColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                  )
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBismillah() {
    return Container(
      alignment: Alignment.center,
      child: Text(
        "بِسْمِ ٱللّٰهِ الرَّحْمٰنِ الرَّحِيمِ",
        style: GoogleFonts.amiri(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: _textColor,
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

  Widget _buildLine(List<Map<String, dynamic>> words) {
    if (words.isEmpty) return const SizedBox.shrink();

    // Check if any word in this line is the end of a verse
    // Note: The API usually provides this metadata or we can deduce it
    // For this premium implementation, we'll check if word is last in verse.

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      alignment: Alignment.center,
      child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: words.map((w) {
            final verseKey = w['verse_key'] as String;
            final parts = verseKey.split(':');
            final sNum = int.parse(parts[0]);
            final ayahNum = int.parse(parts[1]);

            bool isHighlighted = widget.highlightedSurah == sNum && widget.highlightedAyah == ayahNum;

            // Determine if this word is the last word of the verse
            // (Simple heuristic for now, we'll refine if word info supports it)
            // In many APIs, the last word has special location info.
            final bool isEnd = w['is_last_word'] == true || _isLastWordOfVerse(w, words);

            return Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.onAyahTapped != null) {
                      widget.onAyahTapped!(sNum, ayahNum);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isHighlighted ? AppColors.gold.withValues(alpha: 0.22) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Opacity(
                      opacity: (widget.isMemorizationMode && isHighlighted) ? 0.2 : 1.0,
                      child: Text(
                        w['text_uthmani'] ?? "",
                        style: widget.fontFamily == ThemeService.fontAmiri 
                          ? GoogleFonts.amiri(
                              fontSize: widget.fontSize,
                              color: _textColor,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            )
                          : TextStyle(
                              fontFamily: widget.fontFamily,
                              fontSize: widget.fontSize,
                              color: _textColor,
                              height: 1.0,
                            ),
                      ),
                    ),
                  ),
                ),
                if (isEnd) const SizedBox(width: 4),
                if (isEnd) _buildAyahEndMark(ayahNum),
                if (isEnd) const SizedBox(width: 4),
              ],
            );
          }).toList(),
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
}

// ============================================================
//  ORNAMENTAL PAINTERS
// ============================================================

class _PageFramePainter extends CustomPainter {
  final Color color;
  _PageFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final secondaryPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double p = 12.0; // Outer Padding
    const double p2 = 18.0; // Inner border
    
    // 1. Draw Double Outer Frame
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(p, p, size.width - p, size.height - p), const Radius.circular(4)), mainPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(p2, p2, size.width - p2, size.height - p2), const Radius.circular(2)), secondaryPaint);
    
    // 2. Intricate Corners
    final accentPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    const cornerSize = 45.0;
    
    // Top Left - Islamic Star Motif
    _drawIslamicCorner(canvas, const Offset(p, p), cornerSize, accentPaint, isTop: true, isLeft: true);
    // Top Right
    _drawIslamicCorner(canvas, Offset(size.width - p, p), cornerSize, accentPaint, isTop: true, isLeft: false);
    // Bottom Left
    _drawIslamicCorner(canvas, Offset(p, size.height - p), cornerSize, accentPaint, isTop: false, isLeft: true);
    // Bottom Right
    _drawIslamicCorner(canvas, Offset(size.width - p, size.height - p), cornerSize, accentPaint, isTop: false, isLeft: false);
  }

  void _drawIslamicCorner(Canvas canvas, Offset origin, double size, Paint paint, {required bool isTop, required bool isLeft}) {
    final double sx = isLeft ? 1 : -1;
    final double sy = isTop ? 1 : -1;
    
    final path = Path()
      ..moveTo(origin.dx, origin.dy + size * sy)
      ..lineTo(origin.dx, origin.dy)
      ..lineTo(origin.dx + size * sx, origin.dy);
      
    canvas.drawPath(path, paint);
    
    // Add a small decorative diamond at the corner
    const diamondSize = 6.0;
    final diamondPath = Path()
      ..moveTo(origin.dx + (diamondSize * sx), origin.dy)
      ..lineTo(origin.dx, origin.dy + (diamondSize * sy))
      ..lineTo(origin.dx - (diamondSize * sx), origin.dy)
      ..lineTo(origin.dx, origin.dy - (diamondSize * sy))
      ..close();
    canvas.drawPath(diamondPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SurahHeaderPainter extends CustomPainter {
  final Color color;
  _SurahHeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Outer Rect
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    
    // Side Ornaments (Islamic Patterns)
    final sidePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Left Geometric Pattern
    _drawGeometricSide(canvas, Offset(20, size.height/2), sidePaint);
    // Right Geometric Pattern
    _drawGeometricSide(canvas, Offset(size.width - 20, size.height/2), sidePaint);
    
    // Accent lines connecting motifs to center
    canvas.drawLine(Offset(40, size.height/2), Offset(size.width * 0.25, size.height/2), paint);
    canvas.drawLine(Offset(size.width * 0.75, size.height/2), Offset(size.width - 40, size.height/2), paint);
  }

  void _drawGeometricSide(Canvas canvas, Offset center, Paint paint) {
    const double r = 12.0;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      double angle = (i * 45) * 3.14159 / 180;
      double nextAngle = ((i + 1) * 45) * 3.14159 / 180;
      if (i == 0) path.moveTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      path.lineTo(center.dx + r * cos(nextAngle), center.dy + r * sin(nextAngle));
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AyahEndPainter extends CustomPainter {
  final Color color;
  _AyahEndPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
      
    final center = Offset(size.width/2, size.height/2);
    final radius = size.width / 2.2;

    // Draw an 8-pointed Islamic Star (Rub el Hizb style)
    final path = Path();
    for (int i = 0; i < 16; i++) {
      double angle = (i * 22.5) * pi / 180;
      double r = (i % 2 == 0) ? radius : radius * 0.75;
      if (i == 0) {
        path.moveTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      } else {
        path.lineTo(center.dx + r * cos(angle), center.dy + r * sin(angle));
      }
    }
    path.close();
    
    // Fill with a very subtle tint
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.05)..style = PaintingStyle.fill);
    canvas.drawPath(path, paint);
    
    // Inner accent circle
    canvas.drawCircle(center, radius * 0.55, paint..strokeWidth = 0.6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FooterOrnamentPainter extends CustomPainter {
  final Color color;
  _FooterOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2.5, paint);
    
    // Decorative arcs for a multi-layered effect
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2),
      0, 6.28, false, paint..strokeWidth = 0.5
    );
    
    // Small dots at cardinal points
    for (int i = 0; i < 4; i++) {
      double angle = (i * 90) * 3.14159 / 180;
      canvas.drawCircle(Offset(center.dx + (size.width/2.1) * cos(angle), center.dy + (size.width/2.1) * sin(angle)), 1.5, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
