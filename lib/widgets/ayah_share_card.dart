import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/app_colors.dart';

/// 🎨 بطاقة مشاركة الآية الجميلة — Premium Ayah Share Card
class AyahShareCard extends StatefulWidget {
  final String ayahText;
  final String surahName;
  final int ayahNumber;
  final int surahNumber;

  const AyahShareCard({
    super.key,
    required this.ayahText,
    required this.surahName,
    required this.ayahNumber,
    required this.surahNumber,
  });

  @override
  State<AyahShareCard> createState() => _AyahShareCardState();
}

class _AyahShareCardState extends State<AyahShareCard> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isCapturing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'بطاقة الآية',
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance for close button
                ],
              ),
            ),

            // Card preview
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _buildShareCard(),
                  ),
                ),
              ),
            ),

            // Share button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _captureAndShare,
                  icon: _isCapturing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.share_rounded, size: 22),
                  label: Text(
                    _isCapturing ? 'جارٍ التحضير...' : 'مشاركة البطاقة',
                    style: GoogleFonts.amiri(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// البطاقة الفخمة — The Premium Card Widget
  Widget _buildShareCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D2818), // Deep forest green
            Color(0xFF1A3A2A), // Dark emerald
            Color(0xFF0A1F14), // Near black green
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top ornament
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOrnamentLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.auto_awesome, color: AppColors.gold.withValues(alpha: 0.6), size: 18),
                ),
                _buildOrnamentLine(),
              ],
            ),
            const SizedBox(height: 8),

            // Surah name badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'سورة ${widget.surahName}',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ayah text
            Text(
              widget.ayahText,
              style: GoogleFonts.amiri(
                color: Colors.white,
                fontSize: 22,
                height: 2.0,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Ayah number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Text(
                '﴿ ${widget.ayahNumber} ﴾',
                style: GoogleFonts.amiri(
                  color: AppColors.gold.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom ornament
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOrnamentLine(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.auto_awesome, color: AppColors.gold.withValues(alpha: 0.6), size: 18),
                ),
                _buildOrnamentLine(),
              ],
            ),
            const SizedBox(height: 12),

            // App branding
            Text(
              '~ تلا قرآن 🕌',
              style: GoogleFonts.amiri(
                color: AppColors.gold.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrnamentLine() {
    return Container(
      width: 60,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.0),
            AppColors.gold.withValues(alpha: 0.5),
            AppColors.gold.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  /// التقاط البطاقة كصورة ومشاركتها — Capture and share as image
  Future<void> _captureAndShare() async {
    setState(() => _isCapturing = true);

    try {
      // Find the RenderRepaintBoundary
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _isCapturing = false);
        return;
      }

      // Capture image at 3x resolution for crisp quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() => _isCapturing = false);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/tala_ayah_${widget.surahNumber}_${widget.ayahNumber}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Share the image
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '📖 ${widget.surahName} — الآية ${widget.ayahNumber}\n~ تلا قرآن 🕌',
      );
    } catch (e) {
      debugPrint('❌ [AyahShareCard] Capture Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }
}
