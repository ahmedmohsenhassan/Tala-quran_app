import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../models/reciter_model.dart';
import '../services/audio_service.dart';
import '../services/audio_url_service.dart';

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
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _reciters.length,
          itemBuilder: (context, index) {
            final reciter = _reciters[index];
            final isSelected = _selectedReciterId == reciter.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? AppColors.gold
                      : AppColors.emerald.withValues(alpha: 0.1),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(reciter.imageUrl),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.gold
                          : AppColors.emerald.withValues(alpha: 0.2),
                      width: 2,
                    ),
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
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          reciter.qiraah,
                          style: GoogleFonts.amiri(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reciter.subTitle,
                          style: GoogleFonts.amiri(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.gold, size: 28)
                      : IconButton(
                          icon: const Icon(Icons.play_circle_outline_rounded,
                              color: AppColors.textMuted, size: 28),
                          onPressed: () {
                            _selectReciter(reciter.id);
                            // تشغيل عينة (سورة الفاتحة)
                            final url = AudioUrlService.getSurahUrl(
                              reciter: reciter,
                              surahNumber: 1,
                            );
                            AudioService().playFromUrl(url);
                          },
                        ),
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
