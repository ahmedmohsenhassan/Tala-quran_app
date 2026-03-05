import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/surah_screen.dart';
import '../data/surahs.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1F0E), // خلفية أخضر غامق - Dark green background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1F0E), // نفس لون الخلفية - Same as background
        elevation: 0, // بدون ظل - No shadow
        title: Text(
          'تلا قرآن', // اسم التطبيق - App name
          style: GoogleFonts.scheherazadeNew(
            color: const Color(0xFFFFD700), // اللون الذهبي - Golden color
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
              style: GoogleFonts.amiri(
                color: Colors.white,
                fontSize: 20,
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
                    surahName: surah['name'], // اسم السورة - Surah name
                    surahFileName: surah['english_name'].replaceAll(' ', '-') + '.json', // اسم ملف السورة - File name (e.g. Al-Fatiha.json)
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
