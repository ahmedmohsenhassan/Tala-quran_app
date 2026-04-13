// 🕌 مشروع "تلا القرآن" - نقطة البداية
// 🌐 Tala Quran App - Entry Point

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'screens/splash_screen.dart';
import 'screens/mushaf_viewer_screen.dart';
import 'utils/app_colors.dart';
import 'services/quran_database_service.dart';
import 'services/notification_service.dart';
import 'services/smart_notification_service.dart'; // 🔔 Smart Nudges
import 'services/kids_mode_service.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/error_boundary.dart';
import 'services/download_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'services/auth_service.dart';
import 'services/firebase_khatma_service.dart';
import 'services/firestore_sync_service.dart';
import 'services/user_sync_service.dart';
import 'services/content_download_service.dart';
import 'services/achievement_service.dart';
import 'services/spiritual_theme_service.dart';


/// مفتاح التحكم في المظهر — يمكن الوصول إليه من أي مكان في التطبيق
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<String> fontNotifier = ValueNotifier(ThemeService.fontAmiri);
final ValueNotifier<double> fontSizeNotifier = ValueNotifier(1.0);
final ValueNotifier<String> colorNotifier = ValueNotifier(ThemeService.colorEmerald);

/// مفتاح التنقل العالمي — Global Navigator Key for Deep-linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ahmedmohsen.talaquran.audio',
    androidNotificationChannelName: 'Tala Quran Recitation',
    androidNotificationOngoing: true,
  );
  
  // 🎯 FlutterDownloader Background Callback
  // Must be static and registered before runApp
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  FlutterDownloader.registerCallback(DownloadService.callback);

  // 📡 Safe Firebase Initialization (Offline-First)
  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
    debugPrint('✅ Firebase Initialized Successfully');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      isFirebaseInitialized = true;
      debugPrint('ℹ️ Firebase already initialized (duplicate-app). Proceeding...');
    } else {
      debugPrint('⚠️ Firebase Init Failed: $e');
    }
  } catch (e, stack) {
    debugPrint('⚠️ Unexpected Firebase Error: $e');
    debugPrint('🔥 STACK_TRACE: $stack');
  }

  if (isFirebaseInitialized) {
    FirestoreSyncService().syncSurahsToFirestore();
  }

  // 🚀 تحسين سرعة التشغيل - تحميل المظهر فقط بشكل متزامن
  // Fast Startup - Sync only UI critical parameters
  debugPrint('🚀 Starting parallel UI initialization...');
  
  final fThemeMode = ThemeService.getThemeMode();
  final fThemeColor = ThemeService.getThemeColor();
  final fThemeFont = ThemeService.getThemeFont();
  final fFontSize = ThemeService.getFontSizeMultiplier();

  // Wait only for UI-critical settings
  await Future.wait([fThemeMode, fThemeColor, fThemeFont, fFontSize]);

  // 📡 Start background services (Don't block the UI!)
  DownloadService.initialize();
  QuranDatabaseService().initialize().catchError((e) => debugPrint('❌ QuranDB Background Error: $e'));
  NotificationService.initialize().catchError((e) => debugPrint('❌ Notification Background Error: $e'));

  // Unpack UI settings
  final savedTheme = await fThemeMode;
  final savedColor = await fThemeColor;
  final savedFont = await fThemeFont;
  final savedFontSize = await fFontSize;
  
  debugPrint('✅ UI Ready. Theme: $savedTheme');

  themeNotifier.value = _parseThemeMode(savedTheme);
  fontNotifier.value = savedFont;
  fontSizeNotifier.value = savedFontSize;
  colorNotifier.value = savedColor;
  AppColors.applyColorTheme(savedColor);

  // Initialize push notifications in the background
  NotificationService.initialize().then((_) {
    // 🔔 Refresh retention nudges silently
    SmartNotificationService.refreshSmartNudges();
    
    // 📡 Register tap handler for deep-linking
    NotificationService.onNotificationTap = (payload) {
      if (payload == null) return;
      try {
        final data = json.decode(payload);
        if (data['action'] == 'aotd') {
          navigatorKey.currentState?.pushNamed(
            '/mushaf',
            arguments: {
              'surah': data['surah'],
              'ayah': data['ayah'],
              'reciter': data['reciter'],
              'autoPlay': true,
            },
          );
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    };
  }).catchError((e) {
    debugPrint('Notification Init Error: $e');
    return null;
  });

  runApp(
    ErrorBoundary(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => KidsModeService()),
          // Inject AuthService to manage offline/online auth state freely
          ChangeNotifierProvider(
            create: (_) => AuthService(isFirebaseReady: isFirebaseInitialized),
          ),
          // 📡 Provide FirebaseKhatmaService for collaborative features
          Provider(create: (_) => FirebaseKhatmaService()),
          // 📡 Syncing service
          Provider(create: (_) => FirestoreSyncService()),
          ChangeNotifierProvider(create: (_) => UserSyncService()),
          ChangeNotifierProvider(create: (_) => ContentDownloadService()),
          ChangeNotifierProvider(create: (_) => AchievementService()..init()),
          ChangeNotifierProvider(create: (_) => SpiritualThemeService()),
        ],
        child: const TalaQuranApp(),
      ),
    ),
  );
}

ThemeMode _parseThemeMode(String mode) {
  switch (mode) {
    case ThemeService.light:
      return ThemeMode.light;
    case ThemeService.system:
      return ThemeMode.system;
    default:
      return ThemeMode.dark;
  }
}

class TalaQuranApp extends StatelessWidget {
  const TalaQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: fontNotifier,
      builder: (context, currentFont, _) {
        String fontFamily = currentFont;
        if (currentFont == ThemeService.fontNaskh) {
          fontFamily = 'Noto Naskh Arabic';
        }

        return ValueListenableBuilder<String>(
          valueListenable: colorNotifier,
          builder: (context, currentColor, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                return Consumer<KidsModeService>(
                  builder: (context, kidsMode, child) {
                    final isKids = kidsMode.isKidsModeActive;
                    final primaryColor = isKids ? kidsMode.primaryColor : AppColors.gold;
                    final bgColor = isKids
                        ? kidsMode.backgroundColor
                        : (currentMode == ThemeMode.dark
                            ? AppColors.background
                            : AppColors.lightBackground);

                    return MaterialApp(
                      navigatorKey: navigatorKey,
                      debugShowCheckedModeBanner: false,
                      title: 'Tala Al-Quran',
                      themeMode: currentMode,
                      theme: ThemeData(
                        fontFamily: fontFamily,
                        brightness: Brightness.light,
                        primaryColor: primaryColor,
                        scaffoldBackgroundColor:
                            isKids ? bgColor : AppColors.lightBackground,
                        colorScheme: ColorScheme.light(
                          primary: primaryColor,
                          secondary: AppColors.emeraldLight,
                          surface: isKids
                              ? kidsMode.cardColor
                              : AppColors.lightCardBackground,
                        ),
                        textTheme: GoogleFonts.amiriTextTheme().copyWith(
                          bodyLarge: TextStyle(
                              color: isKids
                                  ? Colors.brown
                                  : AppColors.lightTextPrimary),
                          bodyMedium: TextStyle(
                              color: isKids
                                  ? Colors.brown.withValues(alpha: 0.8)
                                  : AppColors.lightTextSecondary),
                        ),
                        pageTransitionsTheme: const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android: BookPageTransitionsBuilder(),
                            TargetPlatform.iOS: BookPageTransitionsBuilder(),
                          },
                        ),
                      ),
                      darkTheme: ThemeData(
                        fontFamily: fontFamily,
                        brightness: Brightness.dark,
                        primaryColor: primaryColor,
                        scaffoldBackgroundColor:
                            isKids ? bgColor : AppColors.background,
                        colorScheme: ColorScheme.dark(
                          primary: primaryColor,
                          secondary: AppColors.emeraldLight,
                          surface: isKids
                              ? kidsMode.cardColor
                              : AppColors.cardBackground,
                        ),
                        textTheme: GoogleFonts.amiriTextTheme(
                                ThemeData.dark().textTheme)
                            .copyWith(
                          bodyLarge: TextStyle(
                              color: isKids
                                  ? Colors.brown
                                  : AppColors.textPrimary),
                          bodyMedium: TextStyle(
                              color: isKids
                                  ? Colors.brown.withValues(alpha: 0.8)
                                  : AppColors.textSecondary),
                        ),
                        pageTransitionsTheme: const PageTransitionsTheme(
                          builders: {
                            TargetPlatform.android: BookPageTransitionsBuilder(),
                            TargetPlatform.iOS: BookPageTransitionsBuilder(),
                          },
                        ),
                      ),
                      // Configure Named Routes for easier deep-linking
                      routes: {
                        '/': (context) => const SplashScreen(),
                        '/mushaf': (context) {
                          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                          return MushafViewerScreen(
                            initialSurah: args?['surah'],
                            initialAyah: args?['ayah'],
                            autoPlayReciter: args?['reciter'],
                            autoPlay: args?['autoPlay'] ?? false,
                          );
                        },
                      },
                      initialRoute: '/',
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

/// مظهر انتقالات الصفحات - يحاكي طي صفحات الكتاب
class BookPageTransitionsBuilder extends PageTransitionsBuilder {
  const BookPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double progress = animation.value;
        final double scale = 0.95 + (progress * 0.05);
        final double angle = (1.0 - progress) * -0.5;
        
        return Transform(
          alignment: Alignment.centerRight,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scaleByVector3(vmath.Vector3(scale, scale, 1.0))
            ..rotateY(angle),
          child: Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
