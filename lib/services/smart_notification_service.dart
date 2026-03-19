import 'notification_service.dart';
import 'streak_service.dart';
import 'khatma_service.dart';

/// خدمة الإشعارات الذكية المتقدمة — Advanced Smart Notification Service
/// Handles the business logic of 'when' and 'what' to notify based on user behavior.
class SmartNotificationService {
  
  /// جدولة الإشعار الذكي القادم — Schedule the next smart notification
  static Future<void> scheduleNextSmartTouch() async {
    final streakData = await StreakService.getStreakData();
    final khatmaStats = await KhatmaService.getStats();
    
    String category = 'quran_calls_you';
    
    // 1. منطق تحديد الفئة بناءً على الحالة
    if (streakData['currentStreak'] == 0) {
      // غائب لفترة — Absent for a while
      category = 'spiritual_companion';
    } else if (!streakData['hasReadToday']) {
      // لم يقرأ اليوم — Hasn't read today
      category = 'wird_reminder';
    } else if (streakData['currentStreak'] >= 3) {
      // مواظب رائع — Great streak
      category = 'custom_motivation';
    }

    // 2. إذا كان لديه ختمة نشطة وقاربت على الانتهاء
    if (khatmaStats['activePlans'] > 0) {
      // يمكن إضافة منطق متقدم هنا للتحقق من تقدم خطة معينة
      // لتبسيط الأمر، نستخدم فئة التحفيز أحياناً
      if (DateTime.now().second % 3 == 0) {
        category = 'khatma_motivation';
      }
    }

    // 3. جدولة الإشعار في وقت مناسب (مثلاً بعد 4 ساعات من آخر نشاط أو في المساء)
    await NotificationService.scheduleCategory(
      category,
      delay: const Duration(hours: 4),
    );
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
