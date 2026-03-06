import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../models/reciter_model.dart';
import '../services/audio_service.dart';

/// شاشة اختيار القراء
/// Recitations (Reciters) selection screen
class RecitationsScreen extends StatefulWidget {
  const RecitationsScreen({super.key});

  @override
  State<RecitationsScreen> createState() => _RecitationsScreenState();
}

class _RecitationsScreenState extends State<RecitationsScreen> {
  String? _selectedReciterId;
  final List<Reciter> _reciters = Reciter.defaultReciters;

  @override
  void initState() {
    super.initState();
    _loadSelectedReciter();
  }

  Future<void> _loadSelectedReciter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedReciterId = prefs.getString('selected_reciter_id') ?? 'al_afasy';
    });
  }

  Future<void> _selectReciter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_reciter_id', id);
    setState(() {
      _selectedReciterId = id;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تغيير القارئ بنجاح',
            style: TextStyle(fontFamily: 'Amiri'),
          ),
          backgroundColor: AppColors.gold,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(
            'اختر القارئ',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reciters.length,
          itemBuilder: (context, index) {
            final reciter = _reciters[index];
            final isSelected = _selectedReciterId == reciter.id;

            return Card(
              color: AppColors.cardBackground,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? AppColors.gold : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(reciter.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                ),
                title: Text(
                  reciter.name,
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  reciter.subTitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.play_circle_fill,
                        color:
                            isSelected ? AppColors.gold : AppColors.textMuted,
                      ),
                      onPressed: () {
                        if (!isSelected) {
                          _selectReciter(reciter.id);
                        }
                        // Preview logic (using first page for preview)
                        AudioService().playFromUrl(
                          reciter.id == 'al_afasy'
                              ? 'https://server7.mp3quran.net/afasi/001.mp3'
                              : 'https://equran.me/audio/1/001.mp3',
                        );
                      },
                    ),
                  ],
                ),
                onTap: () => _selectReciter(reciter.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
