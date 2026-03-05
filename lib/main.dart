// 🕌 مشروع "تلا قرآن" - الصفحة الرئيسية
// 🌐 Tala Quran App - Home Screen
// هذا هو ملف main.dart ويبدأ تشغيل التطبيق من هنا.
// This is the main entry point for the app.

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
        fontFamily: 'Amiri', // خط كلاسيكي عربي
        scaffoldBackgroundColor: const Color(0xFF0B1F14), // خلفية إسلامية داكنة
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFD4AF37), // لون ذهبي
          secondary: const Color(0xFF0B1F14),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const HomeScreen(), // الشاشة الرئيسية
    );
  }
}
