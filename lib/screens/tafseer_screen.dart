import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tafseer_service.dart';
import '../utils/app_colors.dart';

class TafseerScreen extends StatefulWidget {
  final int surahNumber;
  final int? ayahNumber;

  const TafseerScreen({
    super.key,
    required this.surahNumber,
    this.ayahNumber,
  });

  @override
  State<TafseerScreen> createState() => _TafseerScreenState();
}

class _TafseerScreenState extends State<TafseerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tafseers = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTafseer();
  }

  Future<void> _loadTafseer() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final results = await TafseerService.getSurahTafseer(widget.surahNumber);
      if (mounted) {
        setState(() {
          _tafseers = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء تحميل البيانات.';
          _isLoading = false;
        });
      }
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
            'التفسير الميسر',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
            : _error.isNotEmpty
                ? Center(
                    child:
                        Text(_error, style: const TextStyle(color: Colors.red)))
                : _buildTafseerList(),
      ),
    );
  }

  Widget _buildTafseerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _tafseers.length,
      itemBuilder: (context, index) {
        final item = _tafseers[index];
        final ayahNum = int.tryParse(item['aya'].toString()) ?? 0;
        final isHighlighted = widget.ayahNumber == ayahNum;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isHighlighted
                ? AppColors.emerald.withValues(alpha: 0.05)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHighlighted
                  ? AppColors.gold
                  : AppColors.emerald.withValues(alpha: 0.1),
              width: isHighlighted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'الآية $ayahNum',
                        style: GoogleFonts.outfit(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isHighlighted)
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.gold, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item['footnotes'] ?? item['translation'] ?? '',
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
