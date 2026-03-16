import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_plan.dart';
import '../services/khatma_service.dart';
import '../utils/app_colors.dart';

/// شاشة إضافة خطة جديدة — Add New Reading Plan Screen
class AddPlanScreen extends StatefulWidget {
  const AddPlanScreen({super.key});

  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends State<AddPlanScreen> {
  final _titleController = TextEditingController(text: 'ختمة جديدة');
  ReadingPlanType _selectedType = ReadingPlanType.fullQuran;
  int _targetDays = 30;
  int _startPage = 1;
  int _endPage = 604;
  final List<int> _reminderTimes = [20]; // Default 8 PM

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.gold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إنشاء خطة قراءة',
            style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اسم الخطة
              _buildSectionTitle('اسم الخطة'),
              TextField(
                controller: _titleController,
                style: GoogleFonts.amiri(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'مثلاً: ورد الصباح، ختمة رمضان...',
                  hintStyle: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 16),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // نوع الخطة
              _buildSectionTitle('نوع الخطة'),
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // النطاق (إذا كان مخصصاً)
              if (_selectedType == ReadingPlanType.customRange) ...[
                _buildSectionTitle('نطاق القراءة (من صفحة - إلى صفحة)'),
                Row(
                  children: [
                    Expanded(child: _buildNumberInput('من', _startPage, (val) => setState(() => _startPage = val))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildNumberInput('إلى', _endPage, (val) => setState(() => _endPage = val))),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // المدة المستهدفة
              _buildSectionTitle('المدة المستهدفة (أيام)'),
              _buildDaysSelector(),
              const SizedBox(height: 32),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'بدء الخطة الآن',
                    style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _buildTypeOption('ختمة كاملة', ReadingPlanType.fullQuran, Icons.auto_stories_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildTypeOption('نطاق مخصص', ReadingPlanType.customRange, Icons.settings_ethernet_rounded)),
      ],
    );
  }

  Widget _buildTypeOption(String label, ReadingPlanType type, IconData icon) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.gold : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.amiri(color: isSelected ? AppColors.gold : Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.amiri(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          keyboardType: TextInputType.number,
          style: GoogleFonts.outfit(color: Colors.white),
          onChanged: (val) => onChanged(int.tryParse(val) ?? value),
          decoration: InputDecoration(
            hintText: '$value',
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysSelector() {
    return Wrap(
      spacing: 10,
      children: [7, 14, 30, 60, 90].map((days) {
        final isSelected = _targetDays == days;
        return FilterChip(
          label: Text('$days يوم', style: GoogleFonts.amiri(fontSize: 14)),
          selected: isSelected,
          onSelected: (val) => setState(() => _targetDays = days),
          backgroundColor: AppColors.cardBackground,
          selectedColor: AppColors.gold.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: isSelected ? AppColors.gold : Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  void _savePlan() async {
    final now = DateTime.now();
    final plan = ReadingPlan(
      id: 'plan_${now.millisecondsSinceEpoch}', // Simple unique ID
      title: _titleController.text.isEmpty ? 'خطة جديدة' : _titleController.text,
      type: _selectedType,
      startDate: DateTime.now(),
      targetDays: _targetDays,
      startPage: _selectedType == ReadingPlanType.fullQuran ? 1 : _startPage,
      endPage: _selectedType == ReadingPlanType.fullQuran ? 604 : _endPage,
      reminderTimes: _reminderTimes,
    );

    await KhatmaService.createPlan(plan);
    if (mounted) Navigator.pop(context, true);
  }
}
