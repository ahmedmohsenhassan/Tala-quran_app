// 🕌 مشروع "تلا قرآن" - نقطة البداية
// 🌐 Tala Quran App - Entry Point

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';
import 'services/ayah_info_service.dart';
import 'services/notification_service.dart';
import 'services/kids_mode_service.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/error_boundary.dart';
import 'services/download_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

/// مفتاح التحكم في المظهر — يمكن الوصول إليه من أي مكان في التطبيق
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
final ValueNotifier<String> fontNotifier = ValueNotifier(ThemeService.fontAmiri);
final ValueNotifier<double> fontSizeNotifier = ValueNotifier(1.0);
final ValueNotifier<String> colorNotifier = ValueNotifier(ThemeService.colorEmerald);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🎯 FlutterDownloader Background Callback
  // Must be static and registered before runApp
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  FlutterDownloader.registerCallback(DownloadService.callback);

  // 🚀 تحسين سرعة التشغيل باستخدام التحميل المتوازي
  // Optimize startup using parallel loading
  debugPrint('🚀 Starting parallel initialization...');
  
  // Define each task
  final fDownload = DownloadService.initialize();
  final fAyahInfo = AyahInfoService().initialize();
  final fThemeMode = ThemeService.getThemeMode();
  final fThemeColor = ThemeService.getThemeColor();
  final fThemeFont = ThemeService.getThemeFont();
  final fFontSize = ThemeService.getFontSizeMultiplier();

  // Run all in parallel
  await Future.wait([fDownload, fAyahInfo, fThemeMode, fThemeColor, fThemeFont, fFontSize]);

  // Unpack safely after completion
  final savedTheme = await fThemeMode;
  final savedColor = await fThemeColor;
  final savedFont = await fThemeFont;
  final savedFontSize = await fFontSize;
  
  debugPrint('✅ Init completed. Theme: $savedTheme, Color: $savedColor');

  themeNotifier.value = _parseThemeMode(savedTheme);
  fontNotifier.value = savedFont;
  fontSizeNotifier.value = savedFontSize;
  colorNotifier.value = savedColor;
  AppColors.applyColorTheme(savedColor);

  // Initialize push notifications in the background
  NotificationService.initialize().catchError((e) => debugPrint('Notification Init Error: $e'));

  runApp(
    ErrorBoundary(
      child: ChangeNotifierProvider(
        create: (_) => KidsModeService(),
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
                      debugShowCheckedModeBanner: false,
                      title: 'تلا قرآن',
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
                      home: const SplashScreen(),
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
