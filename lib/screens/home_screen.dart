import 'package:flutter/material.dart';
import 'quran_screen.dart';
import 'tafseer_screen.dart';
import 'search_screen.dart';
import 'recitations_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تلا قرآن'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: const [
            HomeItem(title: 'المصحف', icon: Icons.menu_book),
            HomeItem(title: 'التلاوات', icon: Icons.headphones),
            HomeItem(title: 'التفسير', icon: Icons.book_online),
            HomeItem(title: 'البحث', icon: Icons.search),
          ],
        ),
      ),
    );
  }
}

class HomeItem extends StatelessWidget {
  final String title;
  final IconData icon;

  const HomeItem({super.key, required this.title, required this.icon});

  void _navigateToScreen(BuildContext context) {
    Widget screen;

    switch (title) {
      case 'المصحف':
        screen = const QuranScreen();
        break;
      case 'التفسير':
        screen = const TafseerScreen();
        break;
      case 'البحث':
        screen = const SearchScreen();
        break;
      case 'التلاوات':
        screen = const RecitationsScreen();
        break;
      default:
        screen = const Scaffold(
          body: Center(child: Text('الشاشة غير موجودة')),
        );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.teal[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _navigateToScreen(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.teal[800]),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
