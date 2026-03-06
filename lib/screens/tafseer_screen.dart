import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/tafseer_service.dart';
import '../utils/app_colors.dart';

/// شاشة التفسير
/// Tafseer details screen
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
              fontSize: 22,
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
    // التمرير إلى الآية المحددة بعد التحميل
    // Ideally use a ScrollController but for simplicity we filter or highlight

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tafseers.length,
      itemBuilder: (context, index) {
        final item = _tafseers[index];
        final ayahNum = int.tryParse(item['aya'].toString()) ?? 0;
        final isHighlighted = widget.ayahNumber == ayahNum;

        return Card(
          color: isHighlighted
              ? AppColors.gold.withValues(alpha: 0.1)
              : AppColors.cardBackground,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isHighlighted ? AppColors.gold : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'الآية $ayahNum',
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isHighlighted)
                      const Icon(Icons.star, color: AppColors.gold, size: 16),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item['footnotes'] ?? item['translation'] ?? '',
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    height: 1.6,
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
