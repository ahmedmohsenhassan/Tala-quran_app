import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/theme_service.dart';

/// الرسام المشترك لزخارف "المصحف الحقيقي" — Shared Premium Islamic Painters
class PremiumPainters {
  /// رسم إطار مزخرف بالمنحنيات الوردية — Draws a floral ornamental frame
  static void drawFloralFrame({
    required Canvas canvas,
    required Rect rect,
    required Color color,
    required String edition,
    bool hasShadow = true,
  }) {
    // ...
    final bool is1422 = edition == ThemeService.editionMadina1422;
    final bool isWarsh = edition == ThemeService.editionWarsh;

    // 1. Shadow for depth
    if (hasShadow) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), shadowPaint);
    }

    // 2. Main Golden Frame
    final framePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.8), color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = is1422 ? 3.0 : 2.0;

    canvas.drawRect(rect, framePaint);

    // 3. Intricate Corners
    final accentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = is1422 ? 3.5 : 2.5;

    final double cornerSize = isWarsh ? 50.0 : 40.0;
    
    _drawCorner(canvas, rect.topLeft, cornerSize, accentPaint, true, true, edition);
    _drawCorner(canvas, rect.topRight, cornerSize, accentPaint, true, false, edition);
    _drawCorner(canvas, rect.bottomLeft, cornerSize, accentPaint, false, true, edition);
    _drawCorner(canvas, rect.bottomRight, cornerSize, accentPaint, false, false, edition);
  }

  static void _drawCorner(Canvas canvas, Offset origin, double size, Paint paint, bool isTop, bool isLeft, String edition) {
    final double sx = isLeft ? 1 : -1;
    final double sy = isTop ? 1 : -1;
    
    final path = Path()
      ..moveTo(origin.dx, origin.dy + size * sy)
      ..quadraticBezierTo(origin.dx, origin.dy, origin.dx + size * sx, origin.dy);
    
    if (edition != ThemeService.editionWarsh) {
      path.moveTo(origin.dx + (size * 0.3 * sx), origin.dy);
      path.quadraticBezierTo(origin.dx + (size * 0.5 * sx), origin.dy + (size * 0.2 * sy), origin.dx + (size * 0.3 * sx), origin.dy + (size * 0.4 * sy));
      path.quadraticBezierTo(origin.dx + (size * 0.1 * sx), origin.dy + (size * 0.2 * sy), origin.dx + (size * 0.3 * sx), origin.dy);
    }
      
    canvas.drawPath(path, paint);
  }

  /// رسم نجمة إسلامية (لأرقام السور والآيات) — Draws an Islamic star
  static void drawIslamicStar({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
    bool filled = false,
  }) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = filled ? 0 : 1.5;

    final path = Path();
    for (int i = 0; i < 16; i++) {
      double angle = (i * 22.5) * math.pi / 180;
      double r = (i % 2 == 0) ? radius : radius * 0.7;
      if (i == 0) {
        path.moveTo(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      } else {
        path.lineTo(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      }
    }
    path.close();
    
    if (filled) {
        canvas.drawPath(path, paint);
    } else {
        canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill);
        canvas.drawPath(path, paint);
        canvas.drawCircle(center, radius * 0.6, paint..strokeWidth = 0.8);
    }
  }
}
