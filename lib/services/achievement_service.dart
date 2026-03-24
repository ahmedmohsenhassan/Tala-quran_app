import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'streak_service.dart';
import 'reading_stats_service.dart';
import 'khatma_service.dart';

/// نموذج الوسام — Badge Model
class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
  });
}

/// خدمة الإنجازات والأوسمة — Achievement & Badges Service
class AchievementService extends ChangeNotifier {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  List<AchievementBadge> _badges = [];
  List<AchievementBadge> get badges => _badges;

  /// تهيئة الخدمة والتحقق من الأوسمة المستحقة
  Future<void> init() async {
    await _loadBadges();
    await checkNewAchievements();
  }

  Future<void> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList('unlocked_badges') ?? [];

    _badges = [
      AchievementBadge(
        id: 'streak_7',
        title: 'المثابر الأسبوعي',
        description: 'قراءة القرآن لـ 7 أيام متتالية',
        icon: '🔥',
        isUnlocked: unlockedIds.contains('streak_7'),
      ),
      AchievementBadge(
        id: 'verses_100',
        title: 'قارئ مائة آية',
        description: 'إتمام قراءة 100 آية كريمة',
        icon: '📖',
        isUnlocked: unlockedIds.contains('verses_100'),
      ),
      AchievementBadge(
        id: 'khatma_first',
        title: 'الخاتم الأول',
        description: 'إتمام أول ختمة للقرآن الكريم',
        icon: '🏆',
        isUnlocked: unlockedIds.contains('khatma_first'),
      ),
      AchievementBadge(
        id: 'early_bird',
        title: 'فجر النهار',
        description: 'القراءة في وقت الفجر لـ 3 أيام',
        icon: '🌅',
        isUnlocked: unlockedIds.contains('early_bird'),
      ),
      AchievementBadge(
        id: 'tajweed_master',
        title: 'محسن التلاوة',
        description: 'الحصول على دقة 90%+ في اختبار الحفظ',
        icon: '✨',
        isUnlocked: unlockedIds.contains('tajweed_master'),
      ),
    ];
    notifyListeners();
  }

  /// التحقق من الإنجازات الجديدة وتحديث الحالة
  Future<void> checkNewAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList('unlocked_badges') ?? [];
    bool newlyUnlocked = false;

    // 1. التحقق من الاستمرارية — Check Streak
    final streakData = await StreakService.getStreakData();
    final currentStreak = streakData['currentStreak'] as int? ?? 0;
    if (currentStreak >= 7 && !unlockedIds.contains('streak_7')) {
      unlockedIds.add('streak_7');
      newlyUnlocked = true;
    }

    // 2. التحقق من عدد الآيات — Check Verses
    final stats = await ReadingStatsService.getStats();
    final totalAyahs = stats['totalAyahs'] as int? ?? 0;
    if (totalAyahs >= 100 && !unlockedIds.contains('verses_100')) {
      unlockedIds.add('verses_100');
      newlyUnlocked = true;
    }

    // 3. التحقق من الختمات — Check Khatmas
    final khatmas = await KhatmaService.getAllPlans();
    final completedKhatma = khatmas.any((k) => k.isCompleted);
    if (completedKhatma && !unlockedIds.contains('khatma_first')) {
      unlockedIds.add('khatma_first');
      newlyUnlocked = true;
    }

    if (newlyUnlocked) {
      await prefs.setStringList('unlocked_badges', unlockedIds);
      await _loadBadges();
    }
  }
}
