import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/quran_page_helper.dart';
import '../services/theme_service.dart';

class MushafNavigationPicker extends StatefulWidget {
  final int initialJuz;
  final int initialSurah;
  final int initialAyah;
  final String theme;

  const MushafNavigationPicker({
    super.key,
    required this.initialJuz,
    required this.initialSurah,
    required this.initialAyah,
    required this.theme,
  });

  @override
  State<MushafNavigationPicker> createState() => _MushafNavigationPickerState();
}

class _MushafNavigationPickerState extends State<MushafNavigationPicker> {
  late int selectedJuz;
  late int selectedSurah;
  late int selectedAyah;

  late FixedExtentScrollController _juzController;
  late FixedExtentScrollController _surahController;
  late FixedExtentScrollController _ayahController;

  @override
  void initState() {
    super.initState();
    selectedJuz = widget.initialJuz;
    selectedSurah = widget.initialSurah;
    selectedAyah = widget.initialAyah;

    _juzController = FixedExtentScrollController(initialItem: selectedJuz - 1);
    _surahController = FixedExtentScrollController(initialItem: selectedSurah - 1);
    _ayahController = FixedExtentScrollController(initialItem: selectedAyah - 1);
  }

  @override
  void dispose() {
    _juzController.dispose();
    _surahController.dispose();
    _ayahController.dispose();
    super.dispose();
  }

  Color get _deepGreen {
    switch (widget.theme) {
      case ThemeService.mushafPremium: return const Color(0xFF33270F);
      case ThemeService.mushafDark: return const Color(0xFF05110E);
      default: return const Color(0xFF031E17);
    }
  }

  Color get _richGold => const Color(0xFFD4A947);

  void _onJuzChanged(int index) {
    final newJuz = index + 1;
    if (newJuz == selectedJuz) return;

    HapticFeedback.selectionClick();
    setState(() {
      selectedJuz = newJuz;
      // Find the first surah in this Juz
      final firstPage = QuranPageHelper.getPageForJuz(newJuz);
      final firstSurah = QuranPageHelper.getSurahForPage(firstPage);
      
      selectedSurah = firstSurah;
      selectedAyah = 1;
    });

    _surahController.animateToItem(
      selectedSurah - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _ayahController.animateToItem(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onSurahChanged(int index) {
    final newSurah = index + 1;
    if (newSurah == selectedSurah) return;

    HapticFeedback.selectionClick();
    setState(() {
      selectedSurah = newSurah;
      // Update Juz to match the surah's starting page
      final startPage = QuranPageHelper.getPageForSurah(newSurah);
      selectedJuz = QuranPageHelper.getJuzForPage(startPage);
      selectedAyah = 1;
    });

    _juzController.animateToItem(
      selectedJuz - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _ayahController.animateToItem(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onAyahChanged(int index) {
    final newAyah = index + 1;
    if (newAyah == selectedAyah) return;

    HapticFeedback.selectionClick();
    setState(() {
      selectedAyah = newAyah;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int maxAyahs = QuranPageHelper.getAyahCount(selectedSurah);

    return Container(
      height: 420,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _deepGreen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: _richGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, {
                      'surah': selectedSurah,
                      'ayah': selectedAyah,
                    });
                  },
                  child: Text(
                    'حسناً',
                    style: GoogleFonts.amiri(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'انتقاء الآية',
                  style: GoogleFonts.amiri(
                    color: _richGold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: _richGold.withValues(alpha: 0.7)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Column Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('الآية'),
                _buildLabel('السورة'),
                _buildLabel('الجزء'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Pickers
          Expanded(
            child: Stack(
              children: [
                // Selection Highlight
                Center(
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: _richGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.symmetric(
                        horizontal: BorderSide(color: _richGold.withValues(alpha: 0.4), width: 1),
                      ),
                    ),
                  ),
                ),
                
                Row(
                  children: [
                    // Ayah Column
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: _ayahController,
                        itemExtent: 50,
                        childCount: maxAyahs,
                        onSelectedItemChanged: _onAyahChanged,
                        itemBuilder: (context, index) => _buildPickerItem('${index + 1}'),
                      ),
                    ),
                    
                    // Surah Column
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker.builder(
                        scrollController: _surahController,
                        itemExtent: 50,
                        childCount: 114,
                        onSelectedItemChanged: _onSurahChanged,
                        itemBuilder: (context, index) => _buildPickerItem(
                          '${index + 1}. ${QuranPageHelper.surahNames[index]}',
                          isSurah: true,
                        ),
                      ),
                    ),
                    
                    // Juz Column
                    Expanded(
                      child: CupertinoPicker.builder(
                        scrollController: _juzController,
                        itemExtent: 50,
                        childCount: 30,
                        onSelectedItemChanged: _onJuzChanged,
                        itemBuilder: (context, index) => _buildPickerItem('${index + 1}'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.amiri(
        color: _richGold.withValues(alpha: 0.6),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPickerItem(String text, {bool isSurah = false}) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.amiri(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: isSurah ? 18 : 20,
          fontWeight: isSurah ? FontWeight.w500 : FontWeight.bold,
        ),
      ),
    );
  }
}
