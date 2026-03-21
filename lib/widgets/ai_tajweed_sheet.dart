import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_tajweed_service.dart';
import '../utils/app_colors.dart';

class AITajweedSheet extends StatefulWidget {
  final int surah;
  final int ayah;

  const AITajweedSheet({
    super.key,
    required this.surah,
    required this.ayah,
  });

  @override
  State<AITajweedSheet> createState() => _AITajweedSheetState();
}

class _AITajweedSheetState extends State<AITajweedSheet> {
  final AITajweedService _aiService = AITajweedService();
  bool _isRecording = false;
  bool _isAnalyzing = false;
  List<TajweedResult>? _results;

  void _toggleRecording() async {
    if (_isRecording) {
      setState(() => _isRecording = false);
      final transcribedText = await _aiService.stopRecording();
      if (transcribedText != null) {
        _analyze(transcribedText);
      }
    } else {
      final success = await _aiService.startRecording();
      if (success) {
        setState(() => _isRecording = true);
      }
    }
  }

  void _analyze(String transcribedText) async {
    setState(() {
      _isAnalyzing = true;
      _results = null;
    });

    final results = await _aiService.analyzeRecitation(transcribedText, widget.surah, widget.ayah);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _results = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.psychology_outlined, color: AppColors.gold, size: 28),
              const SizedBox(width: 12),
              Text(
                'مختبر تصحيح التجويد (AI)',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_results == null && !_isAnalyzing)
            Column(
              children: [
                Text(
                  'اضغط على الزر وابدأ بالتلاوة ليقوم الذكاء الاصطناعي بتحليل صوتك وتصحيح الأحكام.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          if (_isAnalyzing)
            Column(
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 20),
                Text(
                  'جاري تحليل تلاوتك بمحرك الـ AI...',
                  style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 16),
                ),
                const SizedBox(height: 40),
              ],
            ),
          if (_results != null)
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _results!.map((res) => _buildWordResult(res)).toList(),
              ),
            ),
          
          GestureDetector(
            onTap: _isAnalyzing ? null : _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red.withValues(alpha: 0.2) : AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isRecording ? Colors.red : AppColors.gold,
                  width: 2,
                ),
                boxShadow: _isRecording ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    spreadRadius: 4,
                    blurRadius: 10,
                  )
                ] : [],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isRecording ? Colors.red : AppColors.gold,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isRecording ? 'توقف لإظهار النتائج' : 'ابدأ التسجيل الآن',
            style: GoogleFonts.amiri(
              color: _isRecording ? Colors.red : AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordResult(TajweedResult result) {
    Color statusColor;
    IconData statusIcon;

    switch (result.status) {
      case TajweedStatus.correct:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case TajweedStatus.warning:
        statusColor = Colors.orange;
        statusIcon = Icons.info_outline_rounded;
        break;
      case TajweedStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Tooltip(
      message: result.feedback,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.word,
              style: GoogleFonts.amiri(
                color: statusColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(statusIcon, color: statusColor, size: 16),
          ],
        ),
      ),
    );
  }
}
