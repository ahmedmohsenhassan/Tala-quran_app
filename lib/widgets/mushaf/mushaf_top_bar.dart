import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './mushaf_ui_helpers.dart';

/// 🔝 شريط المعلومات العلوي للمصحف
class MushafTopBar extends StatelessWidget {
  final bool isSanctuaryMode;
  final Animation<double> slideAnimation;
  final int? selectedAyah;
  final int? selectedSurah;
  final String currentSurahName;
  final int currentJuz;
  final String sessionTimeDisplay;
  
  // Colors
  final Color deepGreen;
  final Color richGold;
  final Color darkGold;
  final Color lightGold;

  // Callbacks
  final VoidCallback onCloseSelection;
  final VoidCallback onPlayAyah;
  final VoidCallback onTafseer;
  final VoidCallback onBookmarkAyah;
  final VoidCallback onShowNavigation;
  final VoidCallback onHomePressed;
  final Function(BuildContext) onShowOptions;

  const MushafTopBar({
    super.key,
    required this.isSanctuaryMode,
    required this.slideAnimation,
    this.selectedAyah,
    this.selectedSurah,
    required this.currentSurahName,
    required this.currentJuz,
    required this.sessionTimeDisplay,
    required this.deepGreen,
    required this.richGold,
    required this.darkGold,
    required this.lightGold,
    required this.onCloseSelection,
    required this.onPlayAyah,
    required this.onTafseer,
    required this.onBookmarkAyah,
    required this.onShowNavigation,
    required this.onHomePressed,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isAyahSelected = selectedAyah != null && selectedSurah != null;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: isSanctuaryMode ? 0.0 : 1.0,
        child: IgnorePointer(
          ignoring: isSanctuaryMode,
          child: AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -120 * (1 - slideAnimation.value)),
                child: child,
              );
            },
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 5, 12, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isAyahSelected 
                      ? [
                          richGold.withValues(alpha: 0.95),
                          darkGold.withValues(alpha: 0.90),
                        ]
                      : [
                          deepGreen,
                          deepGreen.withValues(alpha: 0.97),
                          deepGreen.withValues(alpha: 0.85),
                        ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isAyahSelected ? Colors.transparent : richGold.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  boxShadow: isAyahSelected ? [
                    BoxShadow(color: richGold.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ] : [],
                ),
                child: isAyahSelected 
                    ? _buildContextualTopBarItems(context) 
                    : _buildNormalTopBarItems(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextualTopBarItems(BuildContext context) {
    return Row(
      children: [
        MushafIconButton(
          icon: Icons.close_rounded,
          color: deepGreen,
          onPressed: onCloseSelection,
        ),
        const SizedBox(width: 8),
        Text(
          "الآية $selectedAyah",
          style: GoogleFonts.amiri(
            color: deepGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        MushafIconButton(
          icon: Icons.play_arrow_rounded,
          color: deepGreen,
          onPressed: onPlayAyah,
        ),
        MushafIconButton(
          icon: Icons.notes_rounded,
          color: deepGreen,
          onPressed: onTafseer,
        ),
        MushafIconButton(
          icon: Icons.bookmark_add_rounded,
          color: deepGreen,
          onPressed: onBookmarkAyah,
        ),
        MushafIconButton(
          icon: Icons.settings_rounded,
          color: deepGreen,
          onPressed: () => onShowOptions(context),
        ),
      ],
    );
  }

  Widget _buildNormalTopBarItems(BuildContext context) {
    return Row(
      children: [
        MushafHomeButton(
          primaryColor: richGold,
          onPressed: onHomePressed,
        ),
        const SizedBox(width: 8),
        
        Flexible(
          child: GestureDetector(
            onTap: onShowNavigation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: richGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: richGold.withValues(alpha: 0.2), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD4A947), size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currentSurahName,
                            style: GoogleFonts.amiri(
                              color: richGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                            maxLines: 1,
                          ),
                        ),
                        Text(
                          'جزء $currentJuz',
                          style: GoogleFonts.amiri(
                            color: lightGold.withValues(alpha: 0.6),
                            fontSize: 9,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x14FFD700),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0x99FFD700), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    sessionTimeDisplay,
                    style: GoogleFonts.outfit(
                      color: const Color(0xB3FFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            MushafIconButton(
              icon: Icons.settings_suggest_rounded,
              color: richGold,
              onPressed: () => onShowOptions(context),
            ),
          ],
        ),
      ],
    );
  }
}
