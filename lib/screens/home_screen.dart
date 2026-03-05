import 'package:flutter/material.dart';
import '../data/surahs.dart';
import '../screens/surah_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F0E), // خلفية أخضر غامق - Dark green background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1F0E), // نفس لون الخلفية - Same as background
        elevation: 0, // بدون ظل - No shadow
        title: const Text(
          'تلا قرآن', // اسم التطبيق - App name
          style: TextStyle(
            color: Color(0xFFFFD700), // اللون الذهبي - Golden color
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Scheherazade',
          ),
        ),
        centerTitle: true, // توسيط العنوان - Center the title
      ),
      body: ListView.builder(
        itemCount: surahs.length, // عدد السور - Number of surahs
        itemBuilder: (context, index) {
          final surah = surahs[index]; // السورة الحالية - Current surah
          return ListTile(
            title: Text(
              '${surah["number"]}. ${surah["name"]}', // رقم واسم السورة - Surah number and name
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'Amiri',
              ),
            ),
            subtitle: Text(
              surah["english_name"], // الاسم بالإنجليزية - English name
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white), // السهم - Arrow icon
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahScreen(
                    surahNumber: surah['number'], // رقم السورة - Surah number
                    surahName: surah['name'], // اسم السورة - Surah name
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
