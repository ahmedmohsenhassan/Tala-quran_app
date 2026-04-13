import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final bool isNotificationsEnabled;
  final bool isExactAlarmEnabled;

  const NotificationPermissionDialog({
    super.key,
    this.isNotificationsEnabled = true,
    this.isExactAlarmEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF031E17).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.gold,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تنبيهات "تلا القرآن" 📖',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                !isNotificationsEnabled
                    ? 'لتصلك تنبيهات آية اليوم، والوِرد اليومي، وأذكار الصباح والمساء، يرجى تفعيل "الإشعارات" في إعدادات النظام.'
                    : 'لضمان وصول منبهات الفجر والورد اليومي في وقتها تماماً، يحتاج التطبيق إلى إذن "المنبهات والدقائق" (Exact Alarms).',
                style: GoogleFonts.amiri(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'ليس الآن',
                        style: GoogleFonts.amiri(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isNotificationsEnabled) {
                          NotificationService.openNotificationSettings();
                        } else {
                          NotificationService.openExactAlarmSettings();
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF031E17),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'فتح الإعدادات',
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
