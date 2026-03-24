import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import '../data/constellation_data.dart';
import '../widgets/constellation_painter.dart';
import '../utils/app_colors.dart';
import 'mushaf_viewer_screen.dart';

class ConstellationScreen extends StatefulWidget {
  const ConstellationScreen({super.key});

  @override
  State<ConstellationScreen> createState() => _ConstellationScreenState();
}

class _ConstellationScreenState extends State<ConstellationScreen> with SingleTickerProviderStateMixin {
  late List<ConstellationData> _stars;
  final double _galaxySize = 2000.0;
  late AnimationController _animationController;
  
  // ignore: unused_field
  ConstellationData? _selectedStar;

  @override
  void initState() {
    super.initState();
    _stars = ConstellationData.generateGalaxy(_galaxySize);
    _animationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, TransformationController controller) {
    // Convert touch coordinates to galaxy space
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localTouch = renderBox.globalToLocal(details.globalPosition);
    
    // Adjust for InteractiveViewer transformation
    final vmath.Matrix4 transform = controller.value;
    final vmath.Matrix4 inverseTransform = vmath.Matrix4.inverted(transform);
    final vmath.Vector3 transformedTouch = inverseTransform.transform3(vmath.Vector3(localTouch.dx, localTouch.dy, 0));
    final Offset galaxyTouch = Offset(transformedTouch.x, transformedTouch.y);

    ConstellationData? closest;
    double minDistance = 25.0; // Tap tolerance

    for (final star in _stars) {
      final distance = (Offset(star.x, star.y) - galaxyTouch).distance;
      if (distance < minDistance) {
        closest = star;
        minDistance = distance;
      }
    }

    if (closest != null) {
      setState(() {
        _selectedStar = closest;
      });
      _showSurahInfo(closest);
    }
  }

  void _showSurahInfo(ConstellationData star) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SurahInfoDialog(star: star),
    );
  }

  @override
  Widget build(BuildContext context) {
      final transformationController = TransformationController();
      // Center the galaxy
      transformationController.value = vmath.Matrix4.identity()
        ..setTranslationRaw(-(_galaxySize / 2 - 200), -(_galaxySize / 2 - 400), 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: transformationController,
            constrained: false, // Allows the canvas to be larger than the screen
            minScale: 0.1,
            maxScale: 2.0,
            boundaryMargin: const EdgeInsets.all(500),
            child: GestureDetector(
                onTapUp: (details) => _handleTap(details, transformationController),
                child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) => CustomPaint(
                        size: Size(_galaxySize, _galaxySize),
                        painter: ConstellationPainter(
                            stars: _stars,
                            animationValue: _animationController.value,
                        ),
                    ),
                ),
            ),
          ),
          
          // UI Overlays
          Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                          'كوكبة السور',
                          style: GoogleFonts.amiri(
                              color: AppColors.gold,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                          ),
                      ),
                      Text(
                          'اكتشف رحلتك الروحانية عبر النجوم',
                          style: GoogleFonts.amiri(
                              color: AppColors.textMuted,
                              fontSize: 16,
                          ),
                      ),
                  ],
              ),
          ),
        ],
      ),
    );
  }
}

class _SurahInfoDialog extends StatelessWidget {
    final ConstellationData star;
    const _SurahInfoDialog({required this.star});

    @override
    Widget build(BuildContext context) {
        return Container(
            height: 350,
            decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
            ),
            child: Column(
                children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 32),
                    
                    // Star Icon
                    Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (star.isMeccan ? Colors.lightBlueAccent : AppColors.gold).withValues(alpha: 0.1),
                            border: Border.all(color: (star.isMeccan ? Colors.lightBlueAccent : AppColors.gold).withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.stars_rounded, color: star.isMeccan ? Colors.lightBlueAccent : AppColors.gold, size: 40),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                        'سورة ${star.name}',
                        style: GoogleFonts.amiri(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(
                        star.isMeccan ? 'مكية' : 'مدنية',
                        style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 18),
                    ),
                    
                    const Spacer(),
                    
                    Padding(
                        padding: const EdgeInsets.all(24),
                        child: ElevatedButton(
                            onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => MushafViewerScreen(initialSurah: star.surahNumber),
                                    ),
                                );
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(
                                'افتح المصحف',
                                style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}
