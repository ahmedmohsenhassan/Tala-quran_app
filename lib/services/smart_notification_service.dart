import 'dart:convert';
import '../data/ayah_of_the_day_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';
import 'streak_service.dart';
/// خدمة الإشعارات الذكية المتقدمة — Advanced Smart Notification Service
/// Handles the business logic of 'when' and 'what' to notify based on user behavior.
class SmartNotificationService {
  // Unique IDs for sequence nudges to allow cancelling them
  static const int _nudgeId6h = 506;
  static const int _nudgeId24h = 524;
  static const int _nudgeId48h = 548;

  /// تهيئة وتجديد المحفزات الذكية — Refresh and schedule sequential smart nudges
  /// Call this whenever the user finishes a reading session or the app backgrounds.
  static Future<void> refreshSmartNudges() async {
    // 1. Cancel existing pending nudges
    await NotificationService.cancelNotification(_nudgeId6h);
    await NotificationService.cancelNotification(_nudgeId24h);
    await NotificationService.cancelNotification(_nudgeId48h);

    final streakData = await StreakService.getStreakData();
    final bool hasGreatStreak = streakData['currentStreak'] >= 3;

    // 2. Schedule Nudge 1: The Gentle Reminder (6 Hours)
    // Only if they haven't read today yet, or just to keep the connection warm.
    await NotificationService.scheduleExactCategory(
      id: _nudgeId6h,
      category: 'quran_calls_you', 
      delay: const Duration(hours: 6),
    );

    // 3. Schedule Nudge 2: The Daily Anchor (24 Hours)
    await NotificationService.scheduleExactCategory(
      id: _nudgeId24h,
      category: hasGreatStreak ? 'custom_motivation' : 'wird_reminder',
      delay: const Duration(hours: 24),
    );

    // 4. Schedule Nudge 3: The Rescue Call (48 Hours)
    await NotificationService.scheduleExactCategory(
      id: _nudgeId48h,
      category: 'spiritual_companion',
      delay: const Duration(hours: 48),
    );

    // 5. Schedule Ayah of the Day Sequence (Next 7 Days)
    await scheduleAyahOfTheDaySequence();
  }

  /// جدولة سلسلة "آية اليوم" للأيام السبعة القادمة
  /// Schedules the next 7 mornings of spiritual anchors
  static Future<void> scheduleAyahOfTheDaySequence() async {
    final now = tz.TZDateTime.now(tz.local);
    
    for (int i = 0; i < 7; i++) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + i,
        8, // 8:00 AM
        0,
      );

      // Skip if it's already past 8 AM today
      if (scheduledDate.isBefore(now)) continue;

      // Unique ID for each day of the week (1001-1007)
      final int notifId = 1000 + scheduledDate.weekday;
      
      // Select Ayah and Reciter based on day of year to ensure variety
      final dayOfYear = scheduledDate.difference(tz.TZDateTime(tz.local, scheduledDate.year)).inDays;
      final ayah = AyahOfTheDayData.verses[dayOfYear % AyahOfTheDayData.verses.length];
      final reciter = AyahOfTheDayData.reciters[dayOfYear % AyahOfTheDayData.reciters.length];

      final payload = json.encode({
        'action': 'aotd',
        'surah': ayah['surah'],
        'ayah': ayah['ayah'],
        'reciter': reciter['id'],
      });

      await NotificationService.scheduleDetailedNotification(
        id: notifId,
        title: 'آية اليوم 🌅 بصوت ${reciter['name']}',
        body: ayah['tadabbur'],
        scheduledDate: scheduledDate,
        payload: payload,
      );
    }
  }

  /// رسالة تشجيعية مخصصة — Get a custom motivational message
  static Future<Map<String, String>> getPersonalizedMessage() async {
    final streakData = await StreakService.getStreakData();
    
    if (streakData['currentStreak'] == 0) {
      return {
        'title': 'القرآن يناديك 📖',
        'body': 'اشتقنا لنور تلاوتك... لا تجعل الشيطان ينسيك ذكر الله، القرآن أنيسك في قبرك.',
      };
    }
    
    if (streakData['currentStreak'] > 0 && !streakData['hasReadToday']) {
      return {
        'title': 'حافظ على شعلتك 🔥',
        'body': 'لديك سلسلة مواظبة من ${streakData['currentStreak']} أيام! لا تكسرها اليوم، اقرأ ولو صفحة.',
      };
    }

    return {
      'title': 'أنت في معية الله 🕋',
      'body': 'ما شاء الله، مواظبتك على تلاوة القرآن ستكون نوراً لك في الدنيا والآخرة.',
    };
  }
}
