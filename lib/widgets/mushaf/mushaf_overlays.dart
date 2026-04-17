import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

/// 🧘‍♂️ واجهة "محراب التلاوة" - Sanctuary Mode
class MushafSanctuaryOverlay extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onExit;

  const MushafSanctuaryOverlay({
    super.key,
    required this.controller,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onExit,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.15),
        child: Stack(
          children: [
            // Breathing Glow
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.08 * controller.value),
                        Colors.transparent,
                      ],
                      radius: 0.7 + (controller.value * 0.5),
                    ),
                  ),
                );
              },
            ),
            
            // Focus Hint
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.2 + (controller.value * 0.3),
                      child: child,
                    );
                  },
                  child: Text(
                    'محراب التلاوة',
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Flow Indicator
            Positioned(
              bottom: 60,
              left: 60,
              right: 60,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  return Container(
                    height: 1.2,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.gold.withValues(alpha: 0.1 + (0.3 * controller.value)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Exit Information
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'اضغط مطولاً للخروج من المحراب',
                  style: GoogleFonts.amiri(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📏 مؤشر التقدم الجانبي - Progress Rail
class MushafSideProgressRail extends StatelessWidget {
  final int currentPage;
  final double screenHeight;

  const MushafSideProgressRail({
    super.key,
    required this.currentPage,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    const double railPadding = 150;
    final double availableHeight = screenHeight - (railPadding * 2);
    final double progressHeight = availableHeight * (currentPage / 604);

    return Positioned(
      right: 4,
      top: railPadding,
      bottom: railPadding,
      child: Container(
        width: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 4,
              height: progressHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x33FFD700), Color(0xFFFFD700)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              top: progressHeight - 8,
              child: const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 خلفية التطبيق المزخرفة
class MushafPremiumBackground extends StatelessWidget {
  const MushafPremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PremiumBackgroundPainter(),
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
           Color(0xFF031E17),
           Color(0xFF021410),
           Color(0xFF021410),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final ornamentPaint = Paint()
      ..color = const Color(0xFFD4A947).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int i = 1; i <= 8; i++) {
      canvas.drawCircle(Offset(cx, cy), i * 80.0, ornamentPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
