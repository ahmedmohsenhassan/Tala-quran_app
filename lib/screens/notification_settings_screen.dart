import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../utils/app_colors.dart';

/// شاشة إعدادات الإشعارات — Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _enabled = true;
  bool _morning = true;
  bool _evening = true;
  bool _wird = true;
  bool _dailyVerse = true;
  int _morningHour = 6;
  int _eveningHour = 20;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await NotificationService.getSettings();
    if (mounted) {
      setState(() {
        _enabled = settings['enabled'] as bool;
        _morning = settings['morning'] as bool;
        _evening = settings['evening'] as bool;
        _wird = settings['wird'] as bool;
        _dailyVerse = settings['dailyVerse'] as bool;
        _morningHour = settings['morningHour'] as int;
        _eveningHour = settings['eveningHour'] as int;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTime(String type) async {
    final initialHour = type == 'morning' ? _morningHour : _eveningHour;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'morning') {
          _morningHour = picked.hour;
        } else {
          _eveningHour = picked.hour;
        }
      });
      await NotificationService.saveSettings(
        morningHour: type == 'morning' ? picked.hour : null,
        eveningHour: type == 'evening' ? picked.hour : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.gold, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'الإشعارات الذكية',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // رسالة ترحيبية
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),

                  // التفعيل العام
                  _buildToggleCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'تفعيل الإشعارات',
                    subtitle: 'التحكم في جميع الإشعارات الخارجية',
                    value: _enabled,
                    isPrimary: true,
                    onChanged: (val) {
                      setState(() => _enabled = val);
                      NotificationService.saveSettings(enabled: val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // الإشعارات الفرعية
                  AnimatedOpacity(
                    opacity: _enabled ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        // إشعارات الصباح + وقت
                        _buildToggleCard(
                          icon: Icons.wb_sunny_rounded,
                          title: 'إشعارات الصباح',
                          subtitle: 'الساعة ${_formatHour(_morningHour)}',
                          value: _morning,
                          showTimePicker: true,
                          timeType: 'morning',
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _morning = val);
                                  NotificationService.saveSettings(morning: val);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // إشعارات المساء + وقت
                        _buildToggleCard(
                          icon: Icons.nightlight_round,
                          title: 'إشعارات المساء',
                          subtitle: 'الساعة ${_formatHour(_eveningHour)}',
                          value: _evening,
                          showTimePicker: true,
                          timeType: 'evening',
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _evening = val);
                                  NotificationService.saveSettings(evening: val);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // تذكير الورد
                        _buildToggleCard(
                          icon: Icons.local_fire_department_rounded,
                          title: 'تذكير الورد اليومي',
                          subtitle: 'لا تخسر سلسلة المواظبة!',
                          value: _wird,
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _wird = val);
                                  NotificationService.saveSettings(wird: val);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // آية اليوم
                        _buildToggleCard(
                          icon: Icons.auto_awesome,
                          title: 'آية اليوم',
                          subtitle: 'آية قرآنية مؤثرة كل يوم',
                          value: _dailyVerse,
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _dailyVerse = val);
                                  NotificationService.saveSettings(dailyVerse: val);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // معاينة الإشعارات
                  Text(
                    'أنواع الإشعارات',
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewCard('📖 القرآن يناديك', NotificationService.getQuranCallsYou()['body']!),
                  const SizedBox(height: 8),
                  _buildPreviewCard('💚 القرآن يخاطبك', NotificationService.getQuranSpeaksToYou()['body']!),
                  const SizedBox(height: 8),
                  _buildPreviewCard('✨ آية اليوم', NotificationService.getDailyVerse()['body']!),
                  const SizedBox(height: 8),
                  _buildPreviewCard('🔥 تذكير الورد', NotificationService.getSmartMessage()['body']!),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:00 $period';
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.emerald.withValues(alpha: 0.15),
            AppColors.gold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'إشعارات ذكية تذكّرك بالقرآن',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'آيات وتذكيرات تصلك حتى عندما يكون التطبيق مغلقاً',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    bool isPrimary = false,
    bool showTimePicker = false,
    String? timeType,
    ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.emerald.withValues(alpha: 0.1)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? AppColors.gold.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.amiri(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (showTimePicker && onChanged != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _pickTime(timeType!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'تغيير',
                            style: GoogleFonts.amiri(
                              color: AppColors.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.amiri(
                    color: AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.amiri(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
