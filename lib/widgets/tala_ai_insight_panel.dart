import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tala_ai_service.dart';
import '../utils/app_colors.dart';

class TalaAIInsightPanel extends StatefulWidget {
  final int pageNumber;
  const TalaAIInsightPanel({super.key, required this.pageNumber});

  @override
  State<TalaAIInsightPanel> createState() => _TalaAIInsightPanelState();
}

class _TalaAIInsightPanelState extends State<TalaAIInsightPanel> with SingleTickerProviderStateMixin {
  final TalaAIService _aiService = TalaAIService();
  List<SpiritualInsight>? _insights;
  bool _isLoading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _loadInsights();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    try {
      final data = await _aiService.getInsightsForPage(widget.pageNumber);
      if (mounted) {
        setState(() {
          _insights = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💎 Header with Animated Glow
                _buildHeader(),
                const SizedBox(height: 24),
                
                // 📜 Content
                if (_isLoading)
                  _buildLoadingState()
                else if (_insights != null)
                  _buildInsightList()
                else
                  _buildErrorState(),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
        ),
        Row(
          children: [
            Text(
              "Tala AI - رفيق التدبر",
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withValues(alpha: 0.4 * _pulseController.value),
                            blurRadius: 15,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                    );
                  },
                ),
                const Icon(Icons.auto_awesome_rounded, color: Colors.deepPurpleAccent, size: 28),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
      ),
    );
  }

  Widget _buildErrorState() {
     return Center(
      child: Text(
        "تعذر جلب الأفكار الملهمة حالياً.",
        style: GoogleFonts.amiri(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  Widget _buildInsightList() {
    return SizedBox(
      height: 400, // Fixed height for scrolling insights
      child: ListView.separated(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: _insights!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final insight = _insights![index];
          return _buildInsightCard(insight, index);
        },
      ),
    );
  }

  Widget _buildInsightCard(SpiritualInsight insight, int index) {
    IconData icon;
    Color color;

    switch (insight.type) {
      case InsightType.reflection:
        icon = Icons.psychology_rounded;
        color = Colors.lightBlueAccent;
        break;
      case InsightType.thematic:
        icon = Icons.hub_rounded;
        color = AppColors.gold;
        break;
      case InsightType.wisdom:
        icon = Icons.auto_stories_rounded;
        color = Colors.tealAccent.shade400;
        break;
      case InsightType.context:
        icon = Icons.info_outline_rounded;
        color = Colors.orangeAccent;
        break;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 150)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  insight.title,
                  style: GoogleFonts.amiri(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight.content,
              style: GoogleFonts.amiri(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                height: 1.6,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
