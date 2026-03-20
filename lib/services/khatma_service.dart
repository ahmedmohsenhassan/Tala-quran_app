import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_plan.dart';

/// خدمة تتبع الختمة والخطط — Reading Plans & Khatma Service
class KhatmaService {
  static const String _plansKey = 'reading_plans_list';
  static const String _completedCountKey = 'khatma_completed_count';
  static const String _historyKey = 'khatma_history';

  static const int totalPages = 604;

  /// إنشاء خطة جديدة — Create a new Reading Plan
  static Future<void> createPlan(ReadingPlan plan) async {
    final plans = await getAllPlans();
    plans.add(plan);
    await _savePlans(plans);
  }

  /// تحديث تقدم جميع الخطط — Update progress for all active plans
  static Future<void> recordPageProgress(int pageNumber) async {
    final plans = await getAllPlans();
    bool changed = false;

    for (var plan in plans) {
      if (plan.isActive && pageNumber >= plan.startPage && pageNumber <= plan.endPage) {
        // Here we ideally want to track which specific pages are read, 
        // but for now we'll increment if it's within range and not already recorded 
        // (This is a simplified logic, a more robust one would use a bitmask or set of read pages)
        plan.pagesRead++; 
        changed = true;

        if (plan.isCompleted) {
          await _archivePlan(plan);
        }
      }
    }

    if (changed) {
      await _savePlans(plans.where((p) => p.isActive).toList());
    }
  }

  /// أرشفة خطة مكتملة — Archive a completed plan
  static Future<void> _archivePlan(ReadingPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    
    // زيادة عدد الختمات إذا كانت كاملة
    if (plan.type == ReadingPlanType.fullQuran) {
      int count = prefs.getInt(_completedCountKey) ?? 0;
      await prefs.setInt(_completedCountKey, count + 1);
    }

    // حفظ في التاريخ
    final history = await getHistory();
    history.add({
      'id': plan.id,
      'title': plan.title,
      'startDate': plan.startDate.toIso8601String(),
      'endDate': DateTime.now().toIso8601String(),
      'type': plan.type.index,
      'pagesRead': plan.pagesRead,
    });
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// الحصول على كل الخطط النشطة — Get all active plans
  static Future<List<ReadingPlan>> getAllPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final plansStr = prefs.getString(_plansKey);
    if (plansStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(plansStr);
    return jsonList.map((j) => ReadingPlan.fromJson(j)).toList();
  }

  /// حفظ الخطط — Save plans
  static Future<void> _savePlans(List<ReadingPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = plans.map((p) => p.toJson()).toList();
    await prefs.setString(_plansKey, jsonEncode(jsonList));
  }

  /// حذف خطة — Delete a plan
  static Future<void> deletePlan(String id) async {
    final plans = await getAllPlans();
    plans.removeWhere((p) => p.id == id);
    await _savePlans(plans);
  }

  /// الحصول على إحصائيات سريعة — Get quick stats
  static Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final plans = await getAllPlans();
    
    int totalPagesRead = 0; // This should ideally come from a reading_stats_service
    int activePlansCount = plans.length;
    int completedKhatmas = prefs.getInt(_completedCountKey) ?? 0;

    return {
      'activePlans': activePlansCount,
      'completedKhatmas': completedKhatmas,
      'totalPagesRead': totalPagesRead,
    };
  }

  /// عدد الختمات المكتملة — Get completed count
  static Future<int> getCompletedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_completedCountKey) ?? 0;
  }

  /// الحصول على الخطط الجاهزة — Get pre-configured plan presets
  static List<ReadingPlan> getPresets() {
    final now = DateTime.now();
    return [
      ReadingPlan(
        id: 'preset_hifz',
        title: 'ختمة الحفظ',
        type: ReadingPlanType.fullQuran,
        preset: PlanPreset.hifz,
        startDate: now,
        targetDays: 90, // Intensive
        iconIndex: 1, // Gold
      ),
      ReadingPlan(
        id: 'preset_tadabbur',
        title: 'ختمة التدبر',
        type: ReadingPlanType.fullQuran,
        preset: PlanPreset.tadabbur,
        startDate: now,
        targetDays: 180, // Slow/Deep
        iconIndex: 2, // Brown/Leather
      ),
      ReadingPlan(
        id: 'preset_revision',
        title: 'ختمة المراجعة',
        type: ReadingPlanType.fullQuran,
        preset: PlanPreset.revision,
        startDate: now,
        targetDays: 30, // Fast
        iconIndex: 3, // Red/Active
      ),
      ReadingPlan(
        id: 'preset_baqarah',
        title: 'بركة البقرة',
        type: ReadingPlanType.customRange,
        preset: PlanPreset.baqarahBlessing,
        startDate: now,
        startPage: 2,
        endPage: 49,
        targetDays: 3, // Very intensive
        iconIndex: 4, // Green/Special
      ),
    ];
  }

  /// تاريخ الختمات — Get history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString(_historyKey);
    if (historyStr == null) return [];
    final List<dynamic> jsonList = jsonDecode(historyStr);
    return jsonList.cast<Map<String, dynamic>>();
  }
}
