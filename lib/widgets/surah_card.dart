import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'dart:math' as math;

class SurahCard extends StatefulWidget {
  final int number;
  final String name;
  final String revelationType;
  final int totalAyahs;
  final int pageNumber;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.number,
    required this.name,
    required this.revelationType,
    required this.totalAyahs,
    required this.pageNumber,
    required this.onTap,
  });

  @override
  State<SurahCard> createState() => _SurahCardState();
}

class _SurahCardState extends State<SurahCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
    _scaleAnimation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.reverse();
  void _onTapUp(TapUpDetails details) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final bool isMeccan = widget.revelationType == 'Meccan';

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Ornate Bottom Pattern
                Positioned(
                  bottom: -30,
                  right: -30,
                  child: Opacity(
                    opacity: 0.05,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: const Icon(Icons.star_rounded, size: 120, color: AppColors.gold),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Ornate Number Star
                      _buildOrnateNumber(),
                      
                      const SizedBox(width: 16),
                      
                      // Surah Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: GoogleFonts.amiri(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  isMeccan ? Icons.mosque_rounded : Icons.location_city_rounded,
                                  size: 11,
                                  color: AppColors.gold.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isMeccan ? 'مكية' : 'مدنية'} • ${widget.totalAyahs} آيات',
                                  style: GoogleFonts.amiri(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Page Number Badge
                      _buildPageBadge(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrnateNumber() {
    return SizedBox(
      width: 45,
      height: 45,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(45, 45),
            painter: _IslamicStarPainter(
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
          ),
          Text(
            '${widget.number}',
            style: GoogleFonts.outfit(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBadge() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${widget.pageNumber}',
          style: GoogleFonts.outfit(
            color: AppColors.gold.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'صفحة',
          style: GoogleFonts.amiri(
            color: AppColors.gold.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _IslamicStarPainter extends CustomPainter {
  final Color color;
  _IslamicStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width / 2.3;

    final path = Path();
    for (int i = 0; i < 8; i++) {
       final double angle = (i * math.pi / 4) - (math.pi / 8);
       final double outerX = cx + radius * math.cos(angle);
       final double outerY = cy + radius * math.sin(angle);
       
       final double innerAngle = angle + (math.pi / 8);
       final double innerX = cx + (radius * 0.7) * math.cos(innerAngle);
       final double innerY = cy + (radius * 0.7) * math.sin(innerAngle);

       if (i == 0) {
         path.moveTo(outerX, outerY);
       } else {
         path.lineTo(outerX, outerY);
       }
       path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(cx, cy), radius * 0.5, paint..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
