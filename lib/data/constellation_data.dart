import 'dart:math' as math;
import 'surah_metadata.dart';

/// بيانات كوكبة السور — Surah Constellation Data
class ConstellationData {
  final int surahNumber;
  final String name;
  final double x;
  final double y;
  final double size;
  final bool isMeccan;

  ConstellationData({
    required this.surahNumber,
    required this.name,
    required this.x,
    required this.y,
    required this.size,
    required this.isMeccan,
  });

  static List<ConstellationData> generateGalaxy(double canvasSize) {
    final List<ConstellationData> stars = [];
    final center = canvasSize / 2;
    
    // Golden Spiral Equation: r = a * e^(b * theta)
    // We'll use a simpler version for better distribution: r = c * sqrt(n)
    const goldenAngle = 137.508 * (math.pi / 180);
    const scale = 25.0; // Spacing scale

    for (int i = 0; i < 114; i++) {
        final surah = surahMetadata[i];
        final n = i + 1;
        
        // Phyllotaxis pattern (Sunflower)
        final radius = scale * math.sqrt(n);
        final theta = n * goldenAngle;

        final x = center + radius * math.cos(theta);
        final y = center + radius * math.sin(theta);

        // Size based on ayahs (more ayahs = bigger star)
        final ayahCount = surah['totalAyahs'] as int;
        final starSize = (ayahCount / 286 * 10).clamp(3.0, 12.0);

        stars.add(ConstellationData(
            surahNumber: n,
            name: surah['name'] as String,
            x: x,
            y: y,
            size: starSize,
            isMeccan: surah['revelationType'] == 'Meccan',
        ));
    }
    return stars;
  }
}
