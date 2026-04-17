import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:dio/dio.dart';

/// خدمة الإشعارات الذكية — Smart Push Notification Service
/// Layer 1: Local scheduled push notifications
/// Layer 3: Auto-refresh verse database from internet
class NotificationService {
  static const String _enabledKey = 'notifications_enabled';
  static const String _morningKey = 'notif_morning';
  static const String _eveningKey = 'notif_evening';
  static const String _wirdKey = 'notif_wird';
  static const String _dailyVerseKey = 'notif_daily_verse';
  static const String _morningHourKey = 'notif_morning_hour';
  static const String _eveningHourKey = 'notif_evening_hour';

  static final FlutterLocalNotificationsPlugin _notifPlugin =
      FlutterLocalNotificationsPlugin();

  /// Callback for notification taps (Set by main.dart)
  static void Function(String? payload)? onNotificationTap;

  // Notification channel IDs
  static const String _channelId = 'tala_quran_notifications';
  static const String _channelName = 'إشعارات تلا القرآن';
  static const String _channelDesc = 'إشعارات تذكيرية بالقراءة والآيات اليومية';

  // Notification IDs
  static const int _morningNotifId = 100;
  static const int _eveningNotifId = 200;
  static const int _wirdNotifId = 300;
  static const int _dailyVerseNotifId = 400;

  // Verse database (loaded from JSON)
  static Map<String, dynamic>? _verseDb;

  // ===================== INITIALIZATION =====================

  /// تهيئة النظام — Initialize notification system
  static Future<void> initialize() async {
    // 🚀 تهيئة التوقيت والاشعارات بشكل متسلسل لضمان الجاهزية
    tz_data.initializeTimeZones();
    
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      // Fallback to Cairo if detection fails
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped, // Added for background reliability
    );

    // Load verse database and initial schedule
    await _loadVerseDb();
    await _rescheduleAll();
    
    // Auto-refresh from internet (silent)
    await refreshVerseDb();
  }

  /// فحص حالة المنظومة بالكامل — Comprehensive health check of the notification system
  static Future<Map<String, bool>> getNotificationHealth() async {
    final status = await Permission.notification.status;
    
    // Check exact alarm (Android 12+)
    final androidPlugin = _notifPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final bool canScheduleExact = await androidPlugin?.canScheduleExactNotifications() ?? false;
    
    // Check battery optimization
    final bool isBatteryIgnored = await Permission.ignoreBatteryOptimizations.isGranted;

    return {
      'system_enabled': status.isGranted,
      'exact_alarm': canScheduleExact,
      'battery_optimized': !isBatteryIgnored, // True if the OS is still "optimizing" (restricting) us
      'permanently_denied': status.isPermanentlyDenied,
    };
  }

  /// طلب صلاحيات الإشعارات — Request notification permissions
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// طلب استثناء من تحسين البطارية — Request ignore battery optimization
  static Future<bool> requestIgnoreBatteryOptimizations() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// طلب صلاحية المنبهات الدقيقة — Request exact alarm permission
  static Future<void> requestExactAlarmPermission() async {
    // Permission handler can launch the specific setting on Android 13+
    await Permission.scheduleExactAlarm.request();
  }

  /// فتح إعدادات الإشعارات الخاصة بالتطبيق — Open App Notification Settings
  static Future<void> openNotificationSettings() async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {
      await openAppSettings(); // Fallback to general app settings
    }
  }

  /// فتح إعدادات "المنبهات والدقائق" — Open exact alarm settings
  static Future<void> openExactAlarmSettings() async {
    const intent = 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM';
    const channel = MethodChannel('com.ahmed.tala_quran/settings');
    try {
      await channel.invokeMethod('openSettings', intent);
    } catch (e) {
      debugPrint('Error opening exact alarm settings: $e');
    }
  }

  /// معالجة الضغط على الإشعار — Handle notification tap
  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🚀 [Background/Foreground] Notification tapped: ${response.payload}');
    onNotificationTap?.call(response.payload);
  }

  // ===================== VERSE DATABASE =====================

  /// تحميل قاعدة الآيات — Load verse database
  static Future<void> _loadVerseDb() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/quran_notification_verses.json');
      _verseDb = json.decode(jsonStr);
    } catch (e) {
      debugPrint('Error loading verse DB: $e');
    }
  }

  /// تحديث قاعدة الآيات من الإنترنت — Auto-refresh from internet
  static Future<void> refreshVerseDb() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://raw.githubusercontent.com/ahmedmohsenhassan/tala-quran-data/main/notification_verses.json',
        options: Options(
          receiveTimeout: const Duration(seconds: 5), // Reduced timeout
          validateStatus: (status) => status != null, 
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final newData = response.data is String
            ? json.decode(response.data)
            : response.data;

        final currentVersion = _verseDb?['version'] ?? 0;
        final newVersion = newData['version'] ?? 0;

        if (newVersion > currentVersion) {
          _verseDb = newData;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('verse_db_cache', json.encode(newData));
        }
      }
    } catch (_) {
      // Fail silently for network errors to avoid jank
    }
  }

  /// جلب رسالة عشوائية من فئة — Get random message from category
  static Map<String, String> _getRandomFromCategory(String category) {
    if (_verseDb == null) return _getFallbackMessage();

    try {
      final categories = _verseDb!['categories'] as Map<String, dynamic>;
      if (!categories.containsKey(category)) return _getFallbackMessage();

      final verses =
          (categories[category]['verses'] as List).cast<Map<String, dynamic>>();
      if (verses.isEmpty) return _getFallbackMessage();

      final random = Random();
      final verse = verses[random.nextInt(verses.length)];
      return {
        'title': verse['title'] as String,
        'body': verse['body'] as String,
      };
    } catch (_) {
      return _getFallbackMessage();
    }
  }

  static Map<String, String> _getFallbackMessage() {
    return {
      'title': 'القرآن يناديك 📖',
      'body': '﴿وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ﴾',
    };
  }

  /// إرسال إشعار فوري (للاختبار) — Send immediate notification for testing
  static Future<void> sendImmediateNotification({String? title, String? body}) async {
    final message = title != null 
        ? {'title': title, 'body': body ?? ''} 
        : _getRandomFromCategory('daily_verse');

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
      showWhen: true,
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await _notifPlugin.show(
      999, // Test ID
      message['title'],
      message['body'],
      notifDetails,
      payload: 'test_notification',
    );
  }

  // ===================== SCHEDULING =====================

  /// إعادة جدولة جميع الإشعارات — Reschedule all
  static Future<void> _rescheduleAll() async {
    await _notifPlugin.cancelAll();
    final settings = await getSettings();

    if (!settings['enabled']!) return;

    if (settings['morning']!) {
      await _scheduleDailyNotification(
        id: _morningNotifId,
        hour: settings['morningHour'] as int,
        minute: 0,
        category: 'morning',
      );
    }

    if (settings['evening']!) {
      await _scheduleDailyNotification(
        id: _eveningNotifId,
        hour: settings['eveningHour'] as int,
        minute: 0,
        category: 'evening',
      );
    }

    if (settings['wird']!) {
      await _scheduleDailyNotification(
        id: _wirdNotifId,
        hour: 14, // 2 PM default
        minute: 0,
        category: 'wird_reminder',
      );
    }

    if (settings['dailyVerse'] ?? true) {
      await _scheduleDailyNotification(
        id: _dailyVerseNotifId,
        hour: 9, // 9 AM
        minute: 0,
        category: 'daily_verse',
      );
    }
  }

  /// جدولة إشعار يومي — Schedule a single daily notification
  static Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String category,
  }) async {
    final message = _getRandomFromCategory(category);

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(
        message['body']!,
        contentTitle: message['title'],
      ),
    );

    final notifDetails = NotificationDetails(android: androidDetails);

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    // Check for exact alarm permission
    final bool canScheduleExact = await _notifPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications() ?? false;

    await _notifPlugin.zonedSchedule(
      id,
      message['title'],
      message['body'],
      scheduledDate,
      notifDetails,
      androidScheduleMode: canScheduleExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: category,
    );

    debugPrint('📅 Scheduled Daily Notification ($category) at $hour:$minute (ID: $id) [Exact: $canScheduleExact]');
  }
  /// جدولة إشعار مفصل بدقة متناهية (لآية اليوم والمحفزات)
  /// Schedule a detailed exact notification with a specific date and payload
  static Future<void> scheduleDetailedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
      styleInformation: BigTextStyleInformation(''), // Will be set by body
    );

    final bool canScheduleExact = await _notifPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications() ?? false;

    await _notifPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: canScheduleExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // Crucial for daily/weekly
      payload: payload,
    );

    debugPrint('🎯 Scheduled Detailed Notification: $title at $scheduledDate (ID: $id) [Exact: $canScheduleExact]');
  }

  /// جدولة إشعار من فئة معينة بدقة متناهية (للمحفزات الذكية)
  /// Schedule an exact notification that bypasses Doze mode
  static Future<void> scheduleExactCategory({
    required int id, 
    required String category, 
    required Duration delay
  }) async {
    final message = _getRandomFromCategory(category);
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/launcher_icon',
    );

    final bool canScheduleExact = await _notifPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications() ?? false;

    await _notifPlugin.zonedSchedule(
      id,
      message['title']!,
      message['body']!,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: canScheduleExact 
          ? AndroidScheduleMode.exactAllowWhileIdle 
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: category,
    );
    debugPrint('🎯 Scheduled Exact Category Notification ($category) (ID: $id) [Exact: $canScheduleExact]');
  }

  /// إلغاء إشعار محدد — Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifPlugin.cancel(id);
  }

  /// حساب الوقت القادم — Next instance of time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // ===================== SETTINGS =====================

  /// الحصول على إعدادات الإشعارات — Get notification settings
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_enabledKey) ?? true,
      'morning': prefs.getBool(_morningKey) ?? true,
      'evening': prefs.getBool(_eveningKey) ?? true,
      'wird': prefs.getBool(_wirdKey) ?? true,
      'dailyVerse': prefs.getBool(_dailyVerseKey) ?? true,
      'morningHour': prefs.getInt(_morningHourKey) ?? 6,
      'eveningHour': prefs.getInt(_eveningHourKey) ?? 20,
    };
  }

  /// حفظ إعدادات الإشعارات — Save notification settings
  static Future<void> saveSettings({
    bool? enabled,
    bool? morning,
    bool? evening,
    bool? wird,
    bool? dailyVerse,
    int? morningHour,
    int? eveningHour,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (enabled != null) await prefs.setBool(_enabledKey, enabled);
    if (morning != null) await prefs.setBool(_morningKey, morning);
    if (evening != null) await prefs.setBool(_eveningKey, evening);
    if (wird != null) await prefs.setBool(_wirdKey, wird);
    if (dailyVerse != null) await prefs.setBool(_dailyVerseKey, dailyVerse);
    if (morningHour != null) await prefs.setInt(_morningHourKey, morningHour);
    if (eveningHour != null) await prefs.setInt(_eveningHourKey, eveningHour);

    // Reschedule after settings change
    await _rescheduleAll();
  }

  // ===================== SMART MESSAGES =====================

  /// رسالة ذكية حسب الوقت — Smart message based on time of day
  static Map<String, String> getSmartMessage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return _getRandomFromCategory('morning');
    } else if (hour >= 18 || hour < 5) {
      return _getRandomFromCategory('evening');
    } else {
      return _getRandomFromCategory('wird_reminder');
    }
  }

  /// آية اليوم — Daily verse
  static Map<String, String> getDailyVerse() {
    if (_verseDb == null) return _getFallbackMessage();

    try {
      final verses = (_verseDb!['categories']['daily_verse']['verses'] as List)
          .cast<Map<String, dynamic>>();
      final dayOfYear =
          DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
      final verse = verses[dayOfYear % verses.length];
      return {
        'title': verse['title'] as String,
        'body': verse['body'] as String,
      };
    } catch (_) {
      return _getFallbackMessage();
    }
  }

  /// القرآن يناديك — Quran calls you
  static Map<String, String> getQuranCallsYou() {
    return _getRandomFromCategory('quran_calls_you');
  }

  /// القرآن يخاطبك — Quran speaks to you
  static Map<String, String> getQuranSpeaksToYou() {
    return _getRandomFromCategory('quran_speaks_to_you');
  }

  // ===================== IN-APP NOTIFICATION =====================

  /// عرض إشعار داخلي — Show in-app notification
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
        backgroundColor: const Color(0xFF1A5C3A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ======================== LEGACY COMPAT ========================
  // Keep old message lists for backward compatibility
  static final List<Map<String, String>> morningMessages = [
    {'title': '🌅 صباح النور', 'body': 'ابدأ يومك بنور القرآن... اقرأ ولو آية'},
    {'title': '🌤️ صباح الخير', 'body': 'خير ما تبدأ به يومك هو كلام الله'},
  ];

  static final List<Map<String, String>> eveningMessages = [
    {'title': '🌙 مساء القرآن', 'body': 'اختم يومك بآيات من كتاب الله'},
    {'title': '⭐ سكينة الليل', 'body': 'القرآن أُنسك في ليلك وشفيعك يوم القيامة'},
  ];

  static final List<Map<String, String>> wirdMessages = [
    {'title': '🔥 لا تخسر شعلتك!', 'body': 'وردك اليومي ينتظرك... حافظ على المواظبة'},
    {'title': '📖 وقت الورد', 'body': 'هل قرأت وردك اليوم؟ دقائق تكفي لتحافظ على سلسلتك'},
  ];

  static final List<Map<String, String>> dailyVerses = [
    {'title': '📖 آية اليوم', 'body': '﴿فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ﴾'},
    {'title': '📖 آية اليوم', 'body': '﴿إِنَّ مَعَ الْعُسْرِ يُسْرًا﴾'},
  ];
}
