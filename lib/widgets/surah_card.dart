import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

/// كارت سورة قابل لإعادة الاستخدام
/// Reusable Surah card widget
class SurahCard extends StatelessWidget {
  final int number;
  final String name;
  final String englishName;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.number,
    required this.name,
    required this.englishName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.amiri(
            color: AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        subtitle: Text(
          englishName,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        trailing: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.gold,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
