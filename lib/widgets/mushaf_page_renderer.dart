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

  const MushafPageRenderer({
    super.key,
    required this.pageNumber,
    this.onAyahTapped,
    this.highlightedAyah,
    this.highlightedSurah,
    this.isMemorizationMode = false,
    this.theme = ThemeService.mushafClassic,
  });

  @override
  State<MushafPageRenderer> createState() => _MushafPageRendererState();
}

class _MushafPageRendererState extends State<MushafPageRenderer> {
  final QuranTextService _quranService = QuranTextService();
  List<Map<String, dynamic>> _pageData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void didUpdateWidget(MushafPageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPageData();
    }
  }

  Future<void> _loadPageData() async {
    setState(() => _isLoading = true);
    final data = await _quranService.getPageWords(widget.pageNumber);
    if (mounted) {
      setState(() {
        _pageData = data;
        _isLoading = false;
      });
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
          // 1. Ornate Frame
          Positioned.fill(
            child: CustomPaint(
              painter: _PageFramePainter(color: _ornamentColor),
            ),
          ),
          
          // 2. Main Text Content (Fixed 15-line grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 70),
            child: Column(
              children: List.generate(15, (index) {
                int lineIdx = index + 1;
                List<Map<String, dynamic>> lineWords = lines[lineIdx] ?? [];
                
                // Check if this line is a Surah Header
                // API sometimes marks the first word of a surah with a header property or we can check verse_key
                bool isSurahStart = false;
                String surahName = "";
                if (lineWords.isNotEmpty) {
                  final verseKey = lineWords.first['verse_key'] as String;
                  final parts = verseKey.split(':');
                  final sNum = int.parse(parts[0]);
                  final aNum = int.parse(parts[1]);
                  
                  // Check if this is verse 1 and it's not Fatiha (which has special layout usually)
                  // Or use our helper to see if this page is the start page for a surah
                  if (aNum == 1 && QuranPageHelper.getPageForSurah(sNum) == widget.pageNumber) {
                    isSurahStart = true;
                    surahName = QuranPageHelper.surahNames[sNum - 1];
                  }
                }

                return Expanded(
                  child: isSurahStart 
                    ? _buildSurahHeader(surahName)
                    : _buildLine(lineWords),
                );
              }),
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
        ],
      ),
    );
  }

  Widget _buildSurahHeader(String name) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/surah_header_bg.png'), // Fallback if image exists
          fit: BoxFit.contain,
        ),
      ),
      child: CustomPaint(
        painter: _SurahHeaderPainter(color: _ornamentColor),
        child: Center(
          child: Text(
            "سُورَةُ $name",
            style: GoogleFonts.amiri(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
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

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 0,
        textDirection: TextDirection.rtl,
        children: words.map((w) {
          final verseKey = w['verse_key'] as String;
          final parts = verseKey.split(':');
          final sNum = int.parse(parts[0]);
          final ayah = int.parse(parts[1]);

          bool isHighlighted = widget.highlightedSurah == sNum && widget.highlightedAyah == ayah;

          return GestureDetector(
            onTap: () {
              if (widget.onAyahTapped != null) {
                widget.onAyahTapped!(sNum, ayah);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: isHighlighted ? AppColors.gold.withValues(alpha: 0.22) : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Opacity(
                opacity: (widget.isMemorizationMode && isHighlighted) ? 0.2 : 1.0,
                child: Text(
                  w['text_uthmani'] ?? "",
                  style: GoogleFonts.amiri(
                    fontSize: 24,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double p = 15.0; // Padding
    final rect = Rect.fromLTRB(p, p, size.width - p, size.height - p);
    
    // Draw outer frame
    canvas.drawRect(rect, paint);
    
    // Draw ornate corners
    final cornerSize = 40.0;
    final cornerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top Left
    canvas.drawPath(Path()
      ..moveTo(p, p + cornerSize)
      ..lineTo(p, p)
      ..lineTo(p + cornerSize, p), cornerPaint);
      
    // Top Right
    canvas.drawPath(Path()
      ..moveTo(size.width - p - cornerSize, p)
      ..lineTo(size.width - p, p)
      ..lineTo(size.width - p, p + cornerSize), cornerPaint);

    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(p, size.height - p - cornerSize)
      ..lineTo(p, size.height - p)
      ..lineTo(p + cornerSize, size.height - p), cornerPaint);

    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(size.width - p - cornerSize, size.height - p)
      ..lineTo(size.width - p, size.height - p)
      ..lineTo(size.width - p, size.height - p - cornerSize), cornerPaint);
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
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromLTWH(0, 5, size.width, size.height - 10);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    
    // Accent lines
    canvas.drawLine(Offset(10, size.height/2), Offset(size.width/4, size.height/2), paint);
    canvas.drawLine(Offset(size.width * 0.75, size.height/2), Offset(size.width - 10, size.height/2), paint);
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
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2.5, paint);
    
    // Decorative arcs
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2),
      0, 6.28, false, paint..strokeWidth = 1.0
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
