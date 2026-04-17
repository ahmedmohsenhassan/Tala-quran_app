import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/achievement_service.dart';

/// 🏅 معرض أوسمة الإنجاز
class AchievementGallery extends StatelessWidget {
  const AchievementGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementService>(
      builder: (context, service, _) {
        final badges = service.badges;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أوسمة الإنجاز 🏅',
              style: GoogleFonts.amiri(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? AppColors.gold.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: badge.isUnlocked
                              ? AppColors.gold
                              : Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(badge.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          badge.title.split(' ').first,
                          style: TextStyle(
                              color: badge.isUnlocked
                                  ? Colors.white
                                  : Colors.white24,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
