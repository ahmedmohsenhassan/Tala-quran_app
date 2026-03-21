import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hifz_testing_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';

class SmartHifzScreen extends StatefulWidget {
  const SmartHifzScreen({super.key});

  @override
  State<SmartHifzScreen> createState() => _SmartHifzScreenState();
}

class _SmartHifzScreenState extends State<SmartHifzScreen> {
  final HifzTestingService _hifzService = HifzTestingService();

  int _selectedSurah = 1;
  int _selectedAyah = 1;
  bool _isTesting = false;
  bool _isAnalyzing = false;
  HifzTestResult? _result;

  @override
  void initState() {
    super.initState();
  }

  void _startTest() async {
    final success = await _hifzService.startHifzTest();
    if (success) {
      if (mounted) {
        setState(() {
          _isTesting = true;
          _result = null;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الوصول للمايكروفون')),
        );
      }
    }
  }

  void _finishTest() async {
    setState(() {
      _isTesting = false;
      _isAnalyzing = true;
    });

    final transcribedText = await _hifzService.finishHifzTest();
    
    if (transcribedText != null) {
      final result = await _hifzService.evaluateRecitation(transcribedText, _selectedSurah, _selectedAyah);
      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم التقاط أي صوت.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('المساعد الذكي للحفظ 🧠', style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardBackground,
        iconTheme: const IconThemeData(color: AppColors.gold),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSelectorCard(),
              const SizedBox(height: 32),
              if (!_isTesting && !_isAnalyzing && _result == null)
                _buildInstructions(),
              if (_isTesting)
                _buildTestingView(),
              if (_isAnalyzing)
                _buildAnalyzingView(),
              if (_result != null)
                _buildResultView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('اختر المقطع المراد تسميعه', style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InputDecorator(
                  decoration: _inputDecoration('السورة'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedSurah,
                      dropdownColor: AppColors.cardBackground,
                      isExpanded: true,
                      items: List.generate(114, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(QuranPageHelper.surahNames[index], style: GoogleFonts.amiri(color: AppColors.textPrimary)),
                      )),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSurah = val;
                            _selectedAyah = 1; // reset ayah on surah change
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: InputDecorator(
                  decoration: _inputDecoration('الآية'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedAyah,
                      dropdownColor: AppColors.cardBackground,
                      isExpanded: true,
                      // Simplify range for demo (Ideally max verses dynamically)
                      items: List.generate(50, (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}', style: GoogleFonts.amiri(color: AppColors.textPrimary)),
                      )),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAyah = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Icon(Icons.menu_book_rounded, size: 80, color: AppColors.gold.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          'قم بتحديد السورة والآية، ثم اضغط على زر التسجيل أدناه لتسميع الآية من حفظك بدون النظر للمصحف.',
          textAlign: TextAlign.center,
          style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 18),
        ),
        const SizedBox(height: 32),
        _buildMicButton(),
      ],
    );
  }

  Widget _buildTestingView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mic, color: Colors.red, size: 60),
        ),
        const SizedBox(height: 24),
        Text(
          'جاري الاستماع لتسميعك...',
          style: GoogleFonts.amiri(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          ),
          onPressed: _finishTest,
          child: Text('إنهاء التسميع', style: GoogleFonts.amiri(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.gold),
        const SizedBox(height: 24),
        Text(
          'يقوم الذكاء الاصطناعي بتحليل جودة حفظك ومطابقتها للمصحف...',
          textAlign: TextAlign.center,
          style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final score = (_result!.scorePercentage * 100).toInt();
    Color scoreColor = score >= 90 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scoreColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: scoreColor, width: 3),
          ),
          child: Text(
            '$score%',
            style: GoogleFonts.amiri(color: scoreColor, fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          score >= 90 ? 'حفظ ممتاز! 🌟' : score >= 60 ? 'حفظ جيد، يحتاج مراجعة 👍' : 'حفظ ضعيف، راجع الآية أخي الكريم 📖',
          style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 12,
          children: _result!.wordDetails.map((detail) {
            return Tooltip(
              message: detail.feedback,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: detail.isCorrect ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: detail.isCorrect ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  detail.word,
                  style: GoogleFonts.amiri(
                    color: detail.isCorrect ? Colors.green : Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cardBackground,
            side: const BorderSide(color: AppColors.gold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            setState(() {
              _result = null;
            });
          },
          icon: const Icon(Icons.refresh, color: AppColors.gold),
          label: Text('اختبار آية أخرى', style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _startTest,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
        ),
        child: const Icon(Icons.mic_rounded, color: AppColors.gold, size: 48),
      ),
    );
  }
}
