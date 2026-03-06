import 'package:flutter/material.dart';
import '../models/ayah_coordinate.dart';

class AyahHighlighter extends StatelessWidget {
  final List<AyahCoordinate> coordinates;
  // The original image width which the coordinates were based on (e.g. 1024)
  final double imageWidth;
  // The original image height which the coordinates were based on (usually ~1656 for 1024w)
  final double imageHeight;

  const AyahHighlighter({
    super.key,
    required this.coordinates,
    this.imageWidth = 1024.0,
    this.imageHeight = 1656.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / imageWidth;
        final scaleY = constraints.maxHeight / imageHeight;

        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _HighlightPainter(
            coordinates: coordinates,
            scaleX: scaleX,
            scaleY: scaleY,
          ),
        );
      },
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final List<AyahCoordinate> coordinates;
  final double scaleX;
  final double scaleY;

  _HighlightPainter({
    required this.coordinates,
    required this.scaleX,
    required this.scaleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (var coord in coordinates) {
      final rect = Rect.fromLTRB(
        coord.minX * scaleX,
        coord.minY * scaleY,
        coord.maxX * scaleX,
        coord.maxY * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.coordinates != coordinates ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY;
  }
}
