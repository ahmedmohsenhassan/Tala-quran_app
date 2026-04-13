import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import 'mushaf_page_renderer.dart'; // for getArabicTextStyle

class MushafSettingsDialog extends StatefulWidget {
  final Function(double) onQuranFontSizeChanged;
  final Function(double) onTranslationFontSizeChanged;
  final Function(String) onFontChanged;
  final Function(String) onThemeChanged;
  final Function(String) onEditionChanged;
  final bool showTajweed;
  final Function(bool) onTajweedChanged;

  const MushafSettingsDialog({
    super.key,
    required this.onQuranFontSizeChanged,
    required this.onTranslationFontSizeChanged,
    required this.onFontChanged,
    required this.onThemeChanged,
    required this.onEditionChanged,
    required this.showTajweed,
    required this.onTajweedChanged,
  });

  @override
  State<MushafSettingsDialog> createState() => _MushafSettingsDialogState();
}

class _MushafSettingsDialogState extends State<MushafSettingsDialog> {
  double _quranFontSize = 24.0;
  double _translationFontSize = 16.0;
  String _selectedFont = ThemeService.fontAmiri;
  String _selectedTheme = ThemeService.mushafClassic;
  String _selectedEdition = ThemeService.editionMadina1405;
  bool _showTajweed = false;

  // Font options: (displayLabel, fontValue, previewText)
  static const List<(String, String, String)> _fontOptions = [
    ('أميري', ThemeService.fontAmiri, 'بِسْمِ ٱللَّهِ'),
    ('شهرزاد', ThemeService.fontUthmanic, 'بِسْمِ ٱللَّهِ'),
    ('نسخ', ThemeService.fontNaskh, 'بِسْمِ ٱللَّهِ'),
    ('نستعليق', ThemeService.fontIndopak, 'بِسْمِ ٱللَّهِ'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final qSize = await ThemeService.getQuranFontSize();
    final tSize = await ThemeService.getTranslationFontSize();
    final font = await ThemeService.getThemeFont();
    final theme = await ThemeService.getMushafTheme();
    final edition = await ThemeService.getMushafEdition();
    if (mounted) {
      setState(() {
        _quranFontSize = qSize;
        _translationFontSize = tSize;
        _selectedFont = font;
        _selectedTheme = theme;
        _selectedEdition = edition;
        _showTajweed = widget.showTajweed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2E9).withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 4,
          )
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle ─────────────────────────────────────────────
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.green),
                  tooltip: 'إغلاق',
                ),
                Text(
                  'تخصيص المصحف',
                  style: GoogleFonts.amiri(
                    fontSize: 20, fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),

            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Section: حجم الخط القرآني ────────────────────────────────
            _sectionLabel('حجم الخط القرآني'),
            const SizedBox(height: 8),

            // Live Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF5E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8, offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'قُلْ هُوَ ٱللَّهُ أَحَدٌ',
                    style: getArabicTextStyle(
                      fontFamily: _selectedFont,
                      fontSize: _quranFontSize,
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'معاينة حجم ${ _quranFontSize.toInt()} pt',
                    style: GoogleFonts.amiri(
                      fontSize: 11, color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Slider
            _buildSliderSection(
              label: '',
              value: _quranFontSize,
              min: 15.0,
              max: 50.0,
              leftIcon: Icons.text_fields,
              rightIcon: Icons.format_size,
              onChanged: (val) {
                setState(() => _quranFontSize = val);
                ThemeService.setQuranFontSize(val);
                widget.onQuranFontSizeChanged(val);
              },
            ),

            const SizedBox(height: 20),

            // ── Section: اختيار الخط ─────────────────────────────────────
            _sectionLabel('نوع الخط'),
            const SizedBox(height: 10),

            // Font Cards with live preview
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _fontOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final (label, fontValue, preview) = _fontOptions[i];
                  return _buildFontCard(label, fontValue, preview);
                },
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: حجم خط الترجمة ──────────────────────────────────
            _sectionLabel('حجم خط الترجمات'),
            const SizedBox(height: 8),
            _buildSliderSection(
              label: '',
              value: _translationFontSize,
              min: 12.0,
              max: 40.0,
              leftIcon: Icons.text_fields,
              rightIcon: Icons.format_size,
              onChanged: (val) {
                setState(() => _translationFontSize = val);
                ThemeService.setTranslationFontSize(val);
                widget.onTranslationFontSizeChanged(val);
              },
            ),

            const SizedBox(height: 20),

            // ── Section: المظهر (ثيم) ────────────────────────────────────
            _sectionLabel('مظهر الصفحة'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildThemeCard(ThemeService.mushafClassic, 'كلاسيكي',
                    const Color(0xFFFDF5E6), const Color(0xFF00695C)),
                const SizedBox(width: 12),
                _buildThemeCard(ThemeService.mushafPremium, 'ذهبي',
                    const Color(0xFFFFF8E1), const Color(0xFFD4A947)),
                const SizedBox(width: 12),
                _buildThemeCard(ThemeService.mushafDark, 'داكن',
                    const Color(0xFF1A1A1A), const Color(0xFFD4A947)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Section: طبعة المصحف ─────────────────────────────────────
            _sectionLabel('طبعة المصحف'),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildEditionCard('المدينة ١٤٠٥هـ', ThemeService.editionMadina1405,
                      Icons.menu_book_rounded),
                  const SizedBox(width: 10),
                  _buildEditionCard('المدينة ١٤٢٢هـ', ThemeService.editionMadina1422,
                      Icons.auto_stories_rounded),
                  const SizedBox(width: 10),
                  _buildEditionCard('رواية ورش', ThemeService.editionWarsh,
                      Icons.language_rounded),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: تلوين التجويد ───────────────────────────────────
            _buildTajweedToggle(),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: GoogleFonts.amiri(
            fontSize: 15, fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      );

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    IconData? leftIcon,
    IconData? rightIcon,
  }) {
    return Row(
      children: [
        if (leftIcon != null) Icon(leftIcon, size: 16, color: Colors.grey.shade500),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 1).round(),
            activeColor: Colors.green.shade700,
            inactiveColor: Colors.green.withValues(alpha: 0.18),
            thumbColor: Colors.green.shade800,
            onChanged: onChanged,
          ),
        ),
        if (rightIcon != null) Icon(rightIcon, size: 22, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Container(
          width: 36, height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            '${value.toInt()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFontCard(String label, String fontValue, String preview) {
    final bool isSelected = _selectedFont == fontValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFont = fontValue);
        ThemeService.setThemeFont(fontValue);
        widget.onFontChanged(fontValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.green.withValues(alpha: 0.15), blurRadius: 8)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live preview with this font
            Text(
              preview,
              style: getArabicTextStyle(
                fontFamily: fontValue,
                fontSize: 18,
                color: isSelected ? Colors.green.shade800 : Colors.black87,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.fade,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 3),
              const Icon(Icons.check_circle, color: Colors.green, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
      String themeValue, String label, Color bgColor, Color accentColor) {
    final bool isSelected = _selectedTheme == themeValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTheme = themeValue);
        ThemeService.setMushafTheme(themeValue);
        widget.onThemeChanged(themeValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 10)]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أَلَمْ',
              style: GoogleFonts.amiri(
                fontSize: 18, color: bgColor == const Color(0xFF1A1A1A)
                    ? const Color(0xFFE8E0D0)
                    : const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: bgColor == const Color(0xFF1A1A1A)
                    ? Colors.grey.shade300
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle, color: accentColor, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditionCard(String label, String editionValue, IconData icon) {
    final bool isSelected = _selectedEdition == editionValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEdition = editionValue);
        ThemeService.setMushafEdition(editionValue);
        widget.onEditionChanged(editionValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.green.withValues(alpha: 0.15), blurRadius: 8)]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.green.shade700 : Colors.grey.shade500,
                size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.amiri(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.green.shade800 : Colors.black87,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTajweedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.06),
            Colors.green.withValues(alpha: 0.02),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Switch.adaptive(
            value: _showTajweed,
            onChanged: (val) {
              setState(() => _showTajweed = val);
              widget.onTajweedChanged(val);
            },
            activeTrackColor: Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'تلوين أحكام التجويد',
                  style: GoogleFonts.amiri(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'إظهار ألوان المد والغنة والإدغام',
                  style: GoogleFonts.amiri(
                    fontSize: 12, color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.palette_rounded, color: Colors.green, size: 20),
          ),
        ],
      ),
    );
  }
}
