import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الإشعارات الذكية — Smart Notification Service
/// لا تحتاج إلى مكتبة خارجية: تستخدم نظام التذكير الداخلي
class NotificationService {
  static const String _enabledKey = 'notifications_enabled';
  static const String _morningKey = 'notif_morning';
  static const String _eveningKey = 'notif_evening';
  static const String _wirdKey = 'notif_wird';

  // --- رسائل تحفيزية مصنّفة ---

  /// رسائل الصباح — Morning messages
  static final List<Map<String, String>> morningMessages = [
    {'title': '🌅 صباح النور', 'body': 'ابدأ يومك بنور القرآن... اقرأ ولو آية'},
    {'title': '🌤️ صباح الخير', 'body': 'خير ما تبدأ به يومك هو كلام الله'},
    {
      'title': '☀️ يوم جديد',
      'body': 'يوم جديد... فرصة جديدة لتكون أقرب إلى الله'
    },
    {'title': '🌿 صباح البركة', 'body': 'اجعل القرآن رفيق صباحك اليوم'},
    {'title': '🕌 صباح الإيمان', 'body': 'من قرأ حرفاً من كتاب الله فله حسنة'},
    {
      'title': '✨ بداية مباركة',
      'body': 'ردد البسملة وافتح المصحف... بركة يومك تبدأ من هنا'
    },
    {
      'title': '🌱 صباح الطمأنينة',
      'body': 'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'
    },
    {
      'title': '🤲 دعوة الصباح',
      'body': 'اللهم اجعل القرآن ربيع قلبي ونور بصري'
    },
  ];

  /// رسائل المساء — Evening messages
  static final List<Map<String, String>> eveningMessages = [
    {'title': '🌙 مساء القرآن', 'body': 'اختم يومك بآيات من كتاب الله'},
    {
      'title': '⭐ سكينة الليل',
      'body': 'القرآن أُنسك في ليلك وشفيعك يوم القيامة'
    },
    {
      'title': '🌃 مساء الأنس',
      'body': 'لا تنم قبل أن تقرأ وردك... نوم هنيء بإذن الله'
    },
    {'title': '💫 ليلة طيبة', 'body': 'من قرأ سورة الملك قبل النوم شفعت له'},
    {
      'title': '🕯️ هدوء الليل',
      'body': 'في هدوء الليل... افتح المصحف واسمع كلام الله'
    },
    {'title': '🌙 قبل النوم', 'body': 'اقرأ آية الكرسي... حفظك الله حتى تصبح'},
    {'title': '✨ نجوم الليل', 'body': 'كل آية تقرأها نجمة في سماء حسناتك'},
  ];

  /// رسائل تذكير الورد — Wird reminder messages
  static final List<Map<String, String>> wirdMessages = [
    {
      'title': '🔥 لا تخسر شعلتك!',
      'body': 'وردك اليومي ينتظرك... حافظ على المواظبة'
    },
    {
      'title': '📖 وقت الورد',
      'body': 'هل قرأت وردك اليوم؟ دقائق تكفي لتحافظ على سلسلتك'
    },
    {'title': '🎯 التزامك مهم', 'body': 'كل يوم تقرأ فيه خطوة نحو ختم القرآن'},
    {'title': '💪 المواظبة قوة', 'body': 'أحب الأعمال إلى الله أدومها وإن قلّ'},
    {
      'title': '🏆 أنت قريب!',
      'body': 'لا تتوقف الآن... إنجازك القادم قريب جداً'
    },
    {'title': '📿 ذكّر نفسك', 'body': 'القرآن حجة لك أو عليك... اجعله لك'},
    {
      'title': '🌟 شفيعك',
      'body': 'القرآن شفيعك يوم القيامة... هل قرأته اليوم؟'
    },
    {
      'title': '⏰ وقت القراءة',
      'body': 'خصص 10 دقائق فقط... ستشعر بالفرق في يومك'
    },
  ];

  /// آيات يومية — Daily verses
  static final List<Map<String, String>> dailyVerses = [
    {
      'title': '📖 آية اليوم',
      'body': '﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾'
    },
    {
      'title': '📖 آية اليوم',
      'body': '﴿وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ﴾'
    },
    {'title': '📖 آية اليوم', 'body': '﴿إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾'},
    {
      'title': '📖 آية اليوم',
      'body': '﴿وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَى﴾'
    },
    {
      'title': '📖 آية اليوم',
      'body': '﴿رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي﴾'
    },
    {'title': '📖 آية اليوم', 'body': '﴿وَقُل رَّبِّ زِدْنِي عِلْمًا﴾'},
    {
      'title': '📖 آية اليوم',
      'body':
          '﴿وَنُنَزِّلُ مِنَ الْقُرْآنِ مَا هُوَ شِفَاءٌ وَرَحْمَةٌ لِّلْمُؤْمِنِينَ﴾'
    },
  ];

  /// الحصول على إعدادات الإشعارات — Get notification settings
  static Future<Map<String, bool>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_enabledKey) ?? true,
      'morning': prefs.getBool(_morningKey) ?? true,
      'evening': prefs.getBool(_eveningKey) ?? true,
      'wird': prefs.getBool(_wirdKey) ?? true,
    };
  }

  /// حفظ إعدادات الإشعارات — Save notification settings
  static Future<void> saveSettings({
    bool? enabled,
    bool? morning,
    bool? evening,
    bool? wird,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) await prefs.setBool(_enabledKey, enabled);
    if (morning != null) await prefs.setBool(_morningKey, morning);
    if (evening != null) await prefs.setBool(_eveningKey, evening);
    if (wird != null) await prefs.setBool(_wirdKey, wird);
  }

  /// الحصول على رسالة عشوائية حسب الوقت — Get random message based on time
  static Map<String, String> getSmartMessage() {
    final hour = DateTime.now().hour;
    final random = Random();

    if (hour >= 5 && hour < 12) {
      return morningMessages[random.nextInt(morningMessages.length)];
    } else if (hour >= 18 || hour < 5) {
      return eveningMessages[random.nextInt(eveningMessages.length)];
    } else {
      // Afternoon: wird reminder
      return wirdMessages[random.nextInt(wirdMessages.length)];
    }
  }

  /// الحصول على آية يومية — Get daily verse
  static Map<String, String> getDailyVerse() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return dailyVerses[dayOfYear % dailyVerses.length];
  }

  /// عرض إشعار داخلي (In-App Notification) — Show in-app notification
  static void showInAppNotification(BuildContext context,
      {String? customTitle, String? customBody}) {
    final message = customTitle != null
        ? {'title': customTitle, 'body': customBody ?? ''}
        : getSmartMessage();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['title']!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message['body']!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A5C3A), // Emerald
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
