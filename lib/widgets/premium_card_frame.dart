import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'premium_painters.dart';

/// 🖼️ إطار بطاقة فاخر مزخرف
class PremiumCardFrame extends StatelessWidget {
  final Widget child;
  final Color? frameColor;

  const PremiumCardFrame({
    super.key,
    required this.child,
    this.frameColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: CardFramePainter(
                color: frameColor ?? AppColors.gold.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
