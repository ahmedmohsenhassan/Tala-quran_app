import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/reading_plan.dart';
import '../services/khatma_service.dart';
import '../services/firebase_khatma_service.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';

class CreateKhatmaScreen extends StatefulWidget {
  const CreateKhatmaScreen({super.key});

  @override
  State<CreateKhatmaScreen> createState() => _CreateKhatmaScreenState();
}

class _CreateKhatmaScreenState extends State<CreateKhatmaScreen> {
  final _titleController = TextEditingController();
  int _selectedIconIndex = 0;
  RangeValues _juzRange = const RangeValues(1, 30);
  int _durationDays = 30;
  TimeOfDay? _reminderTime;
  PlanPreset _selectedPreset = PlanPreset.general;
  bool _isShared = false;
  bool _isLoading = false;

  final List<Color> _iconColors = [
    const Color(0xFF2196F3), // Blue
    const Color(0xFFD4AF37), // Gold
    const Color(0xFF795548), // Brown
    const Color(0xFFE53935), // Red
    const Color(0xFF43A047), // Green
  ];

  @override
  void initState() {
    super.initState();
    _titleController.text = 'ختمتي - ${DateTime.now().day} رمضان'; // Default as in screenshot
  }

  void _applyPreset(PlanPreset preset) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case PlanPreset.hifz:
          _durationDays = 90;
          _selectedIconIndex = 1;
          break;
        case PlanPreset.tadabbur:
          _durationDays = 180;
          _selectedIconIndex = 2;
          break;
        case PlanPreset.revision:
          _durationDays = 30;
          _selectedIconIndex = 3;
          break;
        case PlanPreset.baqarahBlessing:
          _durationDays = 3;
          _juzRange = const RangeValues(1, 2); // Approximation for Al-Baqarah
          _selectedIconIndex = 4;
          break;
        default:
          _durationDays = 30;
          _selectedIconIndex = 0;
      }
    });
  }

  double get _pagesPerDay {
    int startPage = QuranPageHelper.getPageForJuz(_juzRange.start.toInt());
    int endPage = QuranPageHelper.getJuzEndPage(_juzRange.end.toInt());
    int totalPages = (endPage - startPage + 1).abs();
    return totalPages / _durationDays;
  }

  String get _wirdText {
    double ppd = _pagesPerDay;
    if (ppd >= 20) {
      return '${(ppd / 20).toStringAsFixed(1)} جزء';
    } else {
      return '${ppd.toStringAsFixed(1)} صفحة';
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onSurface: AppColors.gold,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _saveKhatma() async {
    if (_titleController.text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.heavyImpact();
    
    final plan = ReadingPlan(
      id: const Uuid().v4(),
      title: _titleController.text,
      type: _juzRange.start == 1 && _juzRange.end == 30 
          ? ReadingPlanType.fullQuran 
          : ReadingPlanType.customRange,
      preset: _selectedPreset,
      startDate: DateTime.now(),
      targetDays: _durationDays,
      startPage: QuranPageHelper.getPageForJuz(_juzRange.start.toInt()),
      endPage: QuranPageHelper.getJuzEndPage(_juzRange.end.toInt()),
      startJuz: _juzRange.start.toInt(),
      endJuz: _juzRange.end.toInt(),
      iconIndex: _selectedIconIndex,
      reminderTimes: _reminderTime != null ? [_reminderTime!.hour] : [],
    );

    try {
      // 1. Create locally (Always)
      await KhatmaService.createPlan(plan);

      // 2. 📡 Also create in Firebase if shared
      if (_isShared) {
        final firebaseService = FirebaseKhatmaService();
        final cloudId = await firebaseService.createSharedKhatma(plan.title);
        
        if (cloudId == null && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⚠️ لم يتم إنشاء الختمة السحابية، تأكد من الاتصال')),
          );
        }
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في الحفظ: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Modal effect
      body: Container(
        margin: const EdgeInsets.only(top: 80), // Premium sheet look
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPresetHub(),
                    const SizedBox(height: 24),
                    _buildIconPicker(),
                    const SizedBox(height: 24),
                    _buildTextField(),
                    const SizedBox(height: 24),
                    _buildRangeSelector(),
                    const SizedBox(height: 24),
                    _buildDurationSelector(),
                    const SizedBox(height: 24),
                    _buildWirdDisplay(),
                    const SizedBox(height: 24),
                    _buildFrequencyDisplay(),
                    const SizedBox(height: 24),
                    _buildReminderSelector(),
                    const SizedBox(height: 24),
                    _buildSharedToggle(),
                    const SizedBox(height: 40),
                    _buildCreateButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'إنشاء ختمة',
            style: GoogleFonts.amiri(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildIconPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_iconColors.length, (index) {
              final isSelected = _selectedIconIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedIconIndex = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? _iconColors[index].withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: _iconColors[index], width: 2) : null,
                  ),
                  child: Icon(
                    Icons.bookmark_rounded,
                    color: _iconColors[index],
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'سيتم إنشاء علامة مرجعية مرتبطة بالختمة، يمكنك استخدامها لتتبع التقدم في الختمة.',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoKufiArabic(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader(Icons.edit_note_rounded, 'عنوان الختمة'),
        const SizedBox(height: 10),
        TextField(
          controller: _titleController,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoKufiArabic(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.cardBackground.withValues(alpha: 0.3),
            hintText: 'اسم الختمة',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader(Icons.auto_awesome_rounded, 'ختمات مقترحة'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // Arabic RTL feel
          child: Row(
            children: [
              _buildPresetCard(PlanPreset.baqarahBlessing, 'بركة البقرة', Icons.auto_stories_rounded),
              _buildPresetCard(PlanPreset.revision, 'ختمة المراجعة', Icons.rebase_edit),
              _buildPresetCard(PlanPreset.tadabbur, 'ختمة التدبر', Icons.psychology_rounded),
              _buildPresetCard(PlanPreset.hifz, 'ختمة الحفظ', Icons.menu_book_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetCard(PlanPreset preset, String title, IconData icon) {
    bool isSelected = _selectedPreset == preset;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.cardBackground.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? AppColors.gold : AppColors.gold.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: _labelStyle.copyWith(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 8),
            Icon(icon, color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.4), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildWirdDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Text(_wirdText, style: GoogleFonts.outfit(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        _buildSectionHeader(Icons.donut_large_rounded, 'كمية الورد (الجلسة)'),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildSectionHeader(Icons.book_rounded, 'نطاق الختمة'),
        const SizedBox(height: 10),
        RangeSlider(
          values: _juzRange,
          min: 1,
          max: 30,
          divisions: 29,
          activeColor: AppColors.gold,
          inactiveColor: AppColors.gold.withValues(alpha: 0.1),
          onChanged: (values) {
            HapticFeedback.selectionClick();
            setState(() => _juzRange = values);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('الجزء ${_juzRange.end.toInt()}', style: _labelStyle),
            Text('الجزء ${_juzRange.start.toInt()}', style: _labelStyle),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildRoundBtn(Icons.remove, () => setState(() => _durationDays = (_durationDays - 1).clamp(1, 365))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('$_durationDays', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            _buildRoundBtn(Icons.add, () => setState(() => _durationDays = (_durationDays + 1).clamp(1, 365))),
          ],
        ),
        _buildSectionHeader(Icons.bar_chart_rounded, '(الأيام) المدة'),
      ],
    );
  }

  Widget _buildFrequencyDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('كل يوم', style: _labelStyle.copyWith(color: Colors.greenAccent)),
        ),
        _buildSectionHeader(Icons.calendar_month_rounded, 'أيام القراءة'),
      ],
    );
  }

  Widget _buildReminderSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _reminderTime?.format(context) ?? 'بدون',
              style: _labelStyle.copyWith(color: _reminderTime != null ? Colors.greenAccent : Colors.white.withValues(alpha: 0.2)),
            ),
          ),
        ),
        _buildSectionHeader(Icons.notifications_active_rounded, 'وقت التذكير'),
      ],
    );
  }

  Widget _buildCreateButton() {
     return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveKhatma,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading ? AppColors.emerald.withValues(alpha: 0.3) : AppColors.emerald,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: _isLoading 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Text(
              'إنشــاء',
              style: GoogleFonts.notoKufiArabic(fontSize: 18, fontWeight: FontWeight.bold),
            ),
      ),
    );
  }

  Widget _buildSharedToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isShared ? AppColors.gold.withValues(alpha: 0.1) : AppColors.cardBackground.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _isShared ? AppColors.gold : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Switch(
            value: _isShared,
            onChanged: (v) => setState(() => _isShared = v),
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.5),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'مشاركة مع المجتمع',
                style: GoogleFonts.notoKufiArabic(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                'ستظهر الختمة للآخرين للانضمام',
                style: GoogleFonts.notoKufiArabic(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const Icon(Icons.public_rounded, color: AppColors.gold),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: _labelStyle),
        const SizedBox(width: 10),
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 18),
      ],
    );
  }

  Widget _buildRoundBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.notoKufiArabic(
    color: Colors.white.withValues(alpha: 0.7),
    fontSize: 14,
  );
}
