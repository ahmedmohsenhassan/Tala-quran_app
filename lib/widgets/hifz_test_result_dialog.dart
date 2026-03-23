import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hifz_testing_service.dart';
import '../utils/app_colors.dart';

class HifzTestResultDialog extends StatelessWidget {
  final HifzTestResult result;

  const HifzTestResultDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isExcellent = result.scorePercentage >= 0.9;
    final bool isGood = result.scorePercentage >= 0.7;
    
    String title = isExcellent ? 'أحسنت! تلاوة ممتازة 🌟' : (isGood ? 'جيد جداً! استمر 👏' : 'تحتاج للمزيد من المراجعة 💪');
    Color scoreColor = isExcellent ? Colors.green : (isGood ? Colors.orange : Colors.red);

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      title: Column(
        children: [
          Icon(
            isExcellent ? Icons.stars_rounded : Icons.psychology_rounded,
            color: AppColors.gold,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 📊 Score Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: result.scorePercentage,
                  strokeWidth: 8,
                  backgroundColor: scoreColor.withValues(alpha: 0.1),
                  color: scoreColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(result.scorePercentage * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // 📝 Word Analysis
          Text(
            'تحليل الكلمات:',
            style: GoogleFonts.amiri(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: result.wordDetails.map((w) => _buildWordBadge(w)).toList(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text(
              'حسناً',
              style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordBadge(HifzWordDetail word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: word.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: word.isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        word.word,
        style: GoogleFonts.amiri(
          color: word.isCorrect ? Colors.green : Colors.red,
          fontSize: 16,
          fontWeight: word.isCorrect ? FontWeight.normal : FontWeight.bold,
        ),
      ),
    );
  }
}
