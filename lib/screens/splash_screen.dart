import 'package:flutter/material.dart';
import 'package:tala_quran_app/screens/home_screen.dart';

/// شاشة البداية التي تظهر عند تشغيل التطبيق
/// Splash screen that appears on app launch
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // يتم الانتقال تلقائيًا إلى الشاشة الرئيسية بعد 3 ثوانٍ
    // Automatically navigate to HomeScreen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // يحتوي على محتوى مركزي في منتصف الشاشة
      // Contains centered content in the middle of the screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // شعار التطبيق
            // App logo
            Image(
              image: AssetImage('assets/images/logo.png'),
              width: 120,
            ),
            SizedBox(height: 20),

            // اسم التطبيق
            // App name
            Text(
              'تلا قرآن',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              'Tala Quran',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
