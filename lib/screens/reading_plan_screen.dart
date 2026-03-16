import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_plan.dart';
import '../services/khatma_service.dart';
import '../utils/app_colors.dart';
import 'add_plan_screen.dart';

/// الشاشة الرئيسية لخطط القراءة — Reading Plans Dashboard Hub
class ReadingPlanScreen extends StatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  List<ReadingPlan> _plans = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final plans = await KhatmaService.getAllPlans();
    final stats = await KhatmaService.getStats();
    if (mounted) {
      setState(() {
        _plans = plans;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // AppBar مخصص بتصميم مميز
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  'خطط القراءة',
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // تأثير خلفية بسيط
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.gold.withValues(alpha: 0.1),
                            AppColors.background,
                          ],
                        ),
                      ),
                    ),
                    const Center(
                      child: Opacity(
                        opacity: 0.05,
                        child: Icon(Icons.auto_stories_rounded, size: 120, color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
              )
            else if (_plans.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) return _buildSummaryRow();
                      if (index == 1) return const SizedBox(height: 24);
                      
                      final plan = _plans[index - 2];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildPlanCard(plan),
                      );
                    },
                    childCount: _plans.length + 2,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPlanScreen()),
            );
            if (result == true) _loadData();
          },
          backgroundColor: AppColors.gold,
          icon: const Icon(Icons.add, color: Colors.black),
          label: Text(
            'خطة جديدة',
            style: GoogleFonts.amiri(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(child: _buildSummaryItem('الخطط', '${_stats['activePlans']}', Icons.list_alt_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryItem('ختمات', '${_stats['completedKhatmas']}', Icons.auto_awesome_rounded)),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.amiri(color: AppColors.textSecondary, fontSize: 12)),
              Text(value, style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(ReadingPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isOnTrack ? AppColors.gold.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.title,
                style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: plan.isOnTrack ? AppColors.emerald.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plan.isOnTrack ? 'منتظم' : 'متأخر',
                  style: GoogleFonts.amiri(
                    color: plan.isOnTrack ? AppColors.emeraldLight : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تقدم القراءة',
                style: GoogleFonts.amiri(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                '${(plan.progress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('متبقي', '${plan.remainingPages} ص'),
              _buildMiniStat('مستهدف اليوم', '${plan.pagesNeededToday} ص'),
              _buildMiniStat('الأيام', '${plan.daysPassed}/${plan.totalTargetDays}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 12)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories_rounded, size: 80, color: AppColors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            'لا توجد خطط نشطة حالياً',
            style: GoogleFonts.amiri(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ خطة جديدة لتنظيم قراءتك وحفظك',
            style: GoogleFonts.amiri(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
