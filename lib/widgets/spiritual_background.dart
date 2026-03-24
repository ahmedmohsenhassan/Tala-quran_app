import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/spiritual_theme_service.dart';

// ============================================================
//  ANIMATED SPIRITUAL BACKGROUND 🕌✨🌌
// ============================================================
class SpiritualBackground extends StatelessWidget {
  const SpiritualBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpiritualThemeService>(
      builder: (context, service, _) {
        final colors = service.getBackgroundColors();
        return Stack(
          children: [
            // Base Gradient
            AnimatedContainer(
              duration: const Duration(seconds: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
            
            // Dynamic Aura Glow
            Positioned(
              top: -100,
              right: -50,
              child: AnimatedContainer(
                duration: const Duration(seconds: 4),
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: service.getAuraColor(),
                  boxShadow: [
                    BoxShadow(
                      color: service.getAuraColor(),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Heavenly Particles (Noor)
            const Positioned.fill(
              child: NoorParticles(),
            ),
          ],
        );
      },
    );
  }
}

class NoorParticles extends StatefulWidget {
  const NoorParticles({super.key});

  @override
  State<NoorParticles> createState() => _NoorParticlesState();
}

class _NoorParticlesState extends State<NoorParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpiritualThemeService>(
      builder: (context, service, _) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: NoorParticlesPainter(
              progress: _controller.value,
              color: service.getAuraColor().withValues(alpha: 0.3),
            ),
          ),
        );
      },
    );
  }
}

class NoorParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  NoorParticlesPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final random = math.Random(42);

    for (int i = 0; i < 20; i++) {
      final xBase = random.nextDouble() * size.width;
      final yBase = random.nextDouble() * size.height;
      
      // Floating motion
      final x = (xBase + math.sin(progress * 2 * math.pi + i) * 30) % size.width;
      final y = (yBase - progress * size.height) % size.height;
      
      final particleSize = random.nextDouble() * 3 + 1;
      canvas.drawCircle(Offset(x, y), particleSize, paint);
      
      // Glow around particle
      canvas.drawCircle(
        Offset(x, y),
        particleSize * 4,
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
