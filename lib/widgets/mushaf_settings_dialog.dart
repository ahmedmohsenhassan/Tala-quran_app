import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';

class MushafSettingsDialog extends StatefulWidget {
  final Function(double) onQuranFontSizeChanged;
  final Function(double) onTranslationFontSizeChanged;
  final Function(String) onFontChanged;
  final Function(String) onThemeChanged;
  final Function(String) onEditionChanged;
  final bool showTajweed; // 🖌️ New for Phase 103
  final Function(bool) onTajweedChanged; // 🖌️ New for Phase 103

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
  bool _showTajweed = false; // 🖌️ New for Phase 103

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.green),
              ),
              Text(
                "تخصيص الخط",
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(width: 40), // Balance
            ],
          ),
          const Divider(),

          const SizedBox(height: 16),

          // Quran Font Size
          _buildSliderSection(
            label: "حجم النص القرآني",
            value: _quranFontSize,
            min: 15.0,
            max: 50.0,
            onChanged: (val) {
              setState(() => _quranFontSize = val);
              ThemeService.setQuranFontSize(val);
              widget.onQuranFontSizeChanged(val);
            },
          ),

          // Preview Quran Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
            ),
            child: Text(
              "الحمد لله رب",
              style: GoogleFonts.amiri(
                fontSize: _quranFontSize,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: 16),

          // Translation Font Size
          _buildSliderSection(
            label: "حجم الترجمات والتفاسير",
            value: _translationFontSize,
            min: 12.0,
            max: 40.0,
            onChanged: (val) {
              setState(() => _translationFontSize = val);
              ThemeService.setTranslationFontSize(val);
              widget.onTranslationFontSizeChanged(val);
            },
          ),

          const SizedBox(height: 16),

          // Font Toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFontChip("اميِري", ThemeService.fontAmiri),
                _buildFontChip("عثماني", ThemeService.fontUthmanic),
                _buildFontChip("نسخ", ThemeService.fontNaskh),
                _buildFontChip("إندوباك", ThemeService.fontIndopak),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Appearance (Theme Grid)
          Text(
            "المظهر",
            style: GoogleFonts.amiri(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildThemeCircle(ThemeService.mushafClassic, const Color(0xFF031E17)),
              _buildThemeCircle(ThemeService.mushafPremium, const Color(0xFF33270F)),
              _buildThemeCircle(ThemeService.mushafDark, const Color(0xFF1E1E1E)),
            ],
          ),

          const SizedBox(height: 24),

          // Edition Selector Intro
          Text(
            "طبعة المصحف",
            style: GoogleFonts.amiri(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEditionCard("المدينة ١٤٠٥هـ", ThemeService.editionMadina1405),
                _buildEditionCard("المدينة ١٤٢٢هـ", ThemeService.editionMadina1422),
                _buildEditionCard("رواية ورش", ThemeService.editionWarsh),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tajweed Toggle 🎨
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Switch(
                  value: _showTajweed,
                  onChanged: (val) {
                    setState(() => _showTajweed = val);
                    widget.onTajweedChanged(val);
                  },
                  activeThumbColor: Colors.green,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "تلوين التجويد",
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      Text(
                        "إظهار قواعد التجويد بالألوان",
                        style: GoogleFonts.amiri(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.color_lens_rounded, color: Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text("${value.toInt()}"),
            ),
            Text(
              label,
              style: GoogleFonts.amiri(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: Colors.green,
          inactiveColor: Colors.green.withValues(alpha: 0.2),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildThemeCircle(String themeValue, Color color) {
    bool isSelected = _selectedTheme == themeValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTheme = themeValue);
        ThemeService.setMushafTheme(themeValue);
        widget.onThemeChanged(themeValue);
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
          ],
        ),
        child: isSelected 
          ? const Icon(Icons.check, color: Colors.white)
          : null,
      ),
    );
  }

  Widget _buildFontChip(String label, String fontValue) {
    bool isSelected = _selectedFont == fontValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFont = fontValue);
        ThemeService.setThemeFont(fontValue);
        widget.onFontChanged(fontValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEditionCard(String label, String editionValue) {
    bool isSelected = _selectedEdition == editionValue;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedEdition = editionValue);
        ThemeService.setMushafEdition(editionValue);
        widget.onEditionChanged(editionValue);
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.green, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.amiri(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
