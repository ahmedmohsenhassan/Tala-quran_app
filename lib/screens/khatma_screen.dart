import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/khatma_service.dart';
import '../utils/app_colors.dart'; // Corrected import
import 'reading_plan_screen.dart'; // Added import for ReadingPlanScreen

/// شاشة تتبع الختمة — Khatma Tracker Screen
class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({super.key});

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  Map<String, dynamic>? _activeKhatma;
  int _completedCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plans = await KhatmaService.getAllPlans();
    final active = plans.isNotEmpty ? plans.first : null; // Get first active plan as preview
    final count = await KhatmaService.getCompletedCount();
    if (mounted) {
      setState(() {
        _activeKhatma = active?.toJson(); // Convert for legacy UI compatibility
        _completedCount = count;
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    int selectedDays = 30;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setBottomState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'ختمة جديدة',
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر المدة المستهدفة لإتمام الختمة',
                  style: GoogleFonts.amiri(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                // اختيارات المدة — Duration options
                Wrap(
                  spacing: 12,
                  children: [7, 14, 30, 60].map((days) {
                    final isSelected = selectedDays == days;
                    final pagesPerDay = (604 / days).ceil();
                    return GestureDetector(
                      onTap: () => setBottomState(() => selectedDays = days),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$days يوم',
                              style: GoogleFonts.amiri(
                                color:
                                    isSelected ? AppColors.gold : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$pagesPerDay ص/يوم',
                              style: GoogleFonts.outfit(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Navigate to new creation screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReadingPlanScreen()),
                      );
                      if (result == true) _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'بدء الختمة',
                      style: GoogleFonts.amiri(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.gold, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تتبع الختمة',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // عداد الختمات — Completed count
                    _buildCompletedBadge(),
                    const SizedBox(height: 24),

                    // الختمة النشطة — Active Khatma
                    if (_activeKhatma != null) ...[
                      _buildActiveKhatmaCard(),
                    ] else ...[
                      _buildNoActiveKhatma(),
                    ],
                  ],
                ),
              ),
        floatingActionButton: _activeKhatma == null
            ? FloatingActionButton.extended(
                onPressed: _showCreateDialog,
                backgroundColor: AppColors.gold,
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(
                  'ختمة جديدة',
                  style: GoogleFonts.amiri(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCompletedBadge() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: 0.15),
            AppColors.gold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                '$_completedCount',
                style: GoogleFonts.outfit(
                  color: AppColors.gold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _completedCount == 0 ? 'لم تختم القرآن بعد' : 'ختمة مكتملة',
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _completedCount == 0
                      ? 'ابدأ ختمتك الأولى الآن!'
                      : 'أحسنت! واصل المشوار',
                  style: GoogleFonts.amiri(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveKhatmaCard() {
    final k = _activeKhatma!;
    final double progress = k['progress'];
    final int pagesRead = k['pagesRead'];
    final int pagesRemaining = k['pagesRemaining'];
    final int dailyTarget = k['dailyTarget'];
    final int daysRemaining = k['daysRemaining'];
    final bool isOnTrack = k['isOnTrack'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOnTrack
              ? AppColors.gold.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // شريط التقدم الدائري — Circular progress
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: AppColors.gold,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$pagesRead / 604',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // إحصائيات سريعة — Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('📖', '$dailyTarget', 'صفحة/يوم'),
              _buildStat('📅', '$daysRemaining', 'يوم متبقي'),
              _buildStat('📄', '$pagesRemaining', 'صفحة متبقية'),
            ],
          ),
          const SizedBox(height: 16),

          // مؤشر الحالة — Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isOnTrack
                  ? AppColors.emerald.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnTrack ? Icons.check_circle : Icons.warning_rounded,
                  color: isOnTrack ? AppColors.emeraldLight : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnTrack ? 'أنت على المسار الصحيح!' : 'تحتاج تسريع القراءة',
                  style: GoogleFonts.amiri(
                    color: isOnTrack ? AppColors.emeraldLight : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.amiri(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveKhatma() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_rounded,
              color: AppColors.gold.withValues(alpha: 0.5), size: 80),
          const SizedBox(height: 20),
          Text(
            'لا توجد ختمة نشطة',
            style: GoogleFonts.amiri(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أنشئ ختمة جديدة وابدأ رحلتك مع كتاب الله',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
