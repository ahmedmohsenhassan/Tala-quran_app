import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../services/firebase_khatma_service.dart';

/// 🌍 مكون أثر المجتمع العالمي
class CommunityImpactCard extends StatelessWidget {
  const CommunityImpactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirebaseKhatmaService();
    return StreamBuilder<Map<String, dynamic>>(
      stream: service.streamGlobalStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final totalAyahs = stats['totalAyahsRead'] ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.emerald.withValues(alpha: 0.3),
                const Color(0xFF001A16)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أثر مجتمع تالا 🌍',
                        style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'أنت جزء من مجتمع قرأ أكثر من:',
                      style: GoogleFonts.amiri(
                          color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalAyahs آية',
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.public_rounded,
                    color: AppColors.gold, size: 32),
              ),
            ],
          ),
        );
      },
    );
  }
}
