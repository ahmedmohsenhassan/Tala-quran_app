// 🕌 مشروع "تلا قرآن" - نقطة البداية
// 🌐 Tala Quran App - Entry Point

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize push notifications and verse database
  await NotificationService.initialize();

  // Try refreshing verse database from internet (non-blocking)
  NotificationService.refreshVerseDb();

  runApp(const TalaQuranApp());
}

class TalaQuranApp extends StatelessWidget {
  const TalaQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تلا قرآن - Tala Quran',
      theme: ThemeData(
        fontFamily: 'Amiri',
        primaryColor: AppColors.gold,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.emeraldLight,
          surface: AppColors.cardBackground,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      home: const SplashScreen(), // تبدأ بشاشة البداية ثم تنتقل للرئيسية
    );
  }
}
