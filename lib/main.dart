// 🕌 مشروع "تلا قرآن" - نقطة البداية
// 🌐 Tala Quran App - Entry Point

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
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
        scaffoldBackgroundColor: const Color(0xFF0B1F0E),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFD4AF37),
          secondary: const Color(0xFF0B1F0E),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const SplashScreen(), // تبدأ بشاشة البداية ثم تنتقل للرئيسية
    );
  }
}
