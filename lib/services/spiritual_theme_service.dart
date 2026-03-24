import 'package:flutter/material.dart';
import 'dart:async';

/// الفترات الروحانية — Spiritual Periods
enum SpiritualPeriod {
  fajr,    // Dawn (4 AM - 9 AM)
  dhuhr,   // Day (9 AM - 4 PM)
  maghrib, // Sunset (4 PM - 7 PM)
  isha     // Night (7 PM - 4 AM)
}

/// خدمة الأجواء الروحانية الذكية — Smart Spiritual Atmosphere Service
class SpiritualThemeService extends ChangeNotifier {
  static final SpiritualThemeService _instance = SpiritualThemeService._internal();
  factory SpiritualThemeService() => _instance;
  SpiritualThemeService._internal() {
    _startTimer();
  }

  SpiritualPeriod _currentPeriod = SpiritualPeriod.dhuhr;
  SpiritualPeriod get currentPeriod => _currentPeriod;

  Timer? _timer;

  void _startTimer() {
    _updatePeriod();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updatePeriod());
  }

  void _updatePeriod() {
    final hour = DateTime.now().hour;
    SpiritualPeriod newPeriod;

    if (hour >= 4 && hour < 9) {
      newPeriod = SpiritualPeriod.fajr;
    } else if (hour >= 9 && hour < 16) {
      newPeriod = SpiritualPeriod.dhuhr;
    } else if (hour >= 16 && hour < 19) {
      newPeriod = SpiritualPeriod.maghrib;
    } else {
      newPeriod = SpiritualPeriod.isha;
    }

    if (newPeriod != _currentPeriod) {
      _currentPeriod = newPeriod;
      notifyListeners();
    }
  }

  /// ألوان الخلفية — Background Colors
  List<Color> getBackgroundColors() {
    switch (_currentPeriod) {
      case SpiritualPeriod.fajr:
        return [const Color(0xFF001A16), const Color(0xFF003D33), const Color(0xFF0A4D3A)];
      case SpiritualPeriod.dhuhr:
        return [const Color(0xFF021612), const Color(0xFF03251D), const Color(0xFF0A2E26)];
      case SpiritualPeriod.maghrib:
        return [const Color(0xFF1A0F00), const Color(0xFF331A00), const Color(0xFF4D2600)];
      case SpiritualPeriod.isha:
        return [const Color(0xFF0A001A), const Color(0xFF140033), const Color(0xFF021612)];
    }
  }

  /// ألوان الهالة — Aura Colors
  Color getAuraColor() {
    switch (_currentPeriod) {
      case SpiritualPeriod.fajr:
        return const Color(0xFFE8C76A).withValues(alpha: 0.15); // Pale Gold
      case SpiritualPeriod.dhuhr:
        return const Color(0xFFB8860B).withValues(alpha: 0.1);  // Deep Gold
      case SpiritualPeriod.maghrib:
        return Colors.orangeAccent.withValues(alpha: 0.1);      // Amber
      case SpiritualPeriod.isha:
        return Colors.deepPurpleAccent.withValues(alpha: 0.1);  // Spiritual Purple
    }
  }

  /// نصوص التحية — Spiritual Greetings
  String getGreeting() {
    switch (_currentPeriod) {
      case SpiritualPeriod.fajr:
        return 'صباح مبارك بذكر الله';
      case SpiritualPeriod.dhuhr:
        return 'نور حياتك بالقرآن';
      case SpiritualPeriod.maghrib:
        return 'تقبل الله طاعاتكم';
      case SpiritualPeriod.isha:
        return 'ليلة سكينة مع كتاب الله';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
