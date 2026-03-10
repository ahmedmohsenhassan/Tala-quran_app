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
        _enabled = settings['enabled']!;
        _morning = settings['morning']!;
        _evening = settings['evening']!;
        _wird = settings['wird']!;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    switch (key) {
      case 'enabled':
        await NotificationService.saveSettings(enabled: value);
        break;
      case 'morning':
        await NotificationService.saveSettings(morning: value);
        break;
      case 'evening':
        await NotificationService.saveSettings(evening: value);
        break;
      case 'wird':
        await NotificationService.saveSettings(wird: value);
        break;
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
                  // رسالة ترحيبية — Welcome message
                  Container(
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
                          'رسائل تحفيزية متنوعة تبعث في قلبك حب القرآن',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // التفعيل العام — Master toggle
                  _buildToggleCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'تفعيل الإشعارات',
                    subtitle: 'التحكم في جميع الإشعارات',
                    value: _enabled,
                    isPrimary: true,
                    onChanged: (val) {
                      setState(() => _enabled = val);
                      _saveSetting('enabled', val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // إشعارات الصباح — Morning
                  AnimatedOpacity(
                    opacity: _enabled ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        _buildToggleCard(
                          icon: Icons.wb_sunny_rounded,
                          title: 'إشعارات الصباح',
                          subtitle: 'رسائل تحفيزية عند الاستيقاظ',
                          value: _morning,
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _morning = val);
                                  _saveSetting('morning', val);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // إشعارات المساء — Evening
                        _buildToggleCard(
                          icon: Icons.nightlight_round,
                          title: 'إشعارات المساء',
                          subtitle: 'تذكير قبل النوم بالقراءة',
                          value: _evening,
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _evening = val);
                                  _saveSetting('evening', val);
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // تذكير الورد — Wird
                        _buildToggleCard(
                          icon: Icons.local_fire_department_rounded,
                          title: 'تذكير الورد اليومي',
                          subtitle: 'لا تخسر سلسلة المواظبة!',
                          value: _wird,
                          onChanged: _enabled
                              ? (val) {
                                  setState(() => _wird = val);
                                  _saveSetting('wird', val);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // معاينة الإشعارات — Preview
                  Text(
                    'معاينة الإشعارات',
                    style: GoogleFonts.amiri(
                      color: AppColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewCard(
                    '🌅 رسالة صباحية',
                    NotificationService.morningMessages[0]['body']!,
                  ),
                  const SizedBox(height: 8),
                  _buildPreviewCard(
                    '🌙 رسالة مسائية',
                    NotificationService.eveningMessages[0]['body']!,
                  ),
                  const SizedBox(height: 8),
                  _buildPreviewCard(
                    '🔥 تذكير الورد',
                    NotificationService.wirdMessages[0]['body']!,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    bool isPrimary = false,
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
                Text(
                  subtitle,
                  style: GoogleFonts.amiri(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
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
