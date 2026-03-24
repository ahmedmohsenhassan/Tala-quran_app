import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/constellation_data.dart';
import '../utils/app_colors.dart';

class ConstellationPainter extends CustomPainter {
  final List<ConstellationData> stars;
  final double animationValue;

  ConstellationPainter({required this.stars, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 1. Draw connecting lines (Faint Nebula)
    paint.strokeWidth = 0.5;
    for (int i = 0; i < stars.length - 1; i++) {
        final start = Offset(stars[i].x, stars[i].y);
        final end = Offset(stars[i+1].x, stars[i+1].y);
        
        final distance = (start - end).distance;
        if (distance < 100) {
            paint.color = AppColors.gold.withValues(alpha: 0.05 * (1 - distance / 100));
            canvas.drawLine(start, end, paint);
        }
    }

    // 2. Draw Stars
    for (final star in stars) {
        final center = Offset(star.x, star.y);
        final pulse = math.sin(animationValue * 2 * math.pi + star.surahNumber) * 0.2 + 0.8;
        
        final starColor = star.isMeccan ? Colors.lightBlueAccent : AppColors.gold;
        
        // Glow (Aura)
        canvas.drawCircle(
            center,
            star.size * 3 * pulse,
            Paint()
                ..color = starColor.withValues(alpha: 0.1)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );

        // Subatomic Core
        canvas.drawCircle(
            center,
            star.size * pulse,
            Paint()
                ..color = starColor.withValues(alpha: 0.4)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );

        // Bright Point
        canvas.drawCircle(
            center,
            star.size * 0.4,
            Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) => true;
}
