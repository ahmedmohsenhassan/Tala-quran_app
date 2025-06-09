import 'package:flutter/material.dart';
import 'screens/home_screen.dart';  // هذا الاستيراد يشير لملف الشاشة الجديدة

void main() {
  runApp(const TalaQuranApp());
}

class TalaQuranApp extends StatelessWidget {
  const TalaQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تلا قرآن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Cairo',
        primarySwatch: Colors.teal,
      ),
      home: const HomeScreen(),  // استخدام الشاشة التي استوردناها
    );
  }
}
