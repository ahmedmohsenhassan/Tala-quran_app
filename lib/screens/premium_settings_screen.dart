import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_settings/app_settings.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/settings_service.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';

class PremiumSettingsScreen extends StatefulWidget {
  const PremiumSettingsScreen({super.key});

  @override
  State<PremiumSettingsScreen> createState() => _PremiumSettingsScreenState();
}

class _PremiumSettingsScreenState extends State<PremiumSettingsScreen> {
  bool _keepScreenOn = true;
  bool _nightMode = true;
  bool _showDecorations = true;
  bool _updateNotifications = true;
  // Note: _readingMethod and _lastPageAction were removed as they were not used in the UI

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final keepOn = await SettingsService.getKeepScreenOn();
    final showDeco = await SettingsService.getShowDecorations();
    final updateNotif = await SettingsService.getUpdateNotifications();
    final themeMode = await ThemeService.getThemeMode();

    if (mounted) {
      setState(() {
        _keepScreenOn = keepOn;
        _showDecorations = showDeco;
        _updateNotifications = updateNotif;
        _nightMode = themeMode == ThemeService.dark;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('عرض', Icons.tv_rounded),
                  _buildToggleTile(
                    'إضاءة الخلفية',
                    'تحديد ما إذا كان سوف تظل الشاشة مضاءة أو لا أثناء القراءة أو الاستماع',
                    _keepScreenOn,
                    (val) {
                      setState(() => _keepScreenOn = val);
                      SettingsService.setKeepScreenOn(val);
                      if (val) {
                        WakelockPlus.enable();
                      } else {
                        WakelockPlus.disable();
                      }
                    },
                  ),
                  _buildSettingsTile(
                    'اختيار اللغة',
                    'اختر لغة التطبيق المفضلة لك من هذا الاختيار',
                    Icons.language_rounded,
                    () {},
                  ),
                  _buildSettingsTile(
                    'طريقة التصفح',
                    'تغيير وضع التصفح سواء بالصفحات أو بالتمرير أو السحب لأعلى',
                    Icons.import_contacts_rounded,
                    () {},
                  ),
                  _buildSettingsTile(
                    'طريقة تحميل السور',
                    'يحدد هذا الاختيار إذا ما كان النص القرآني سوف يحمل كله في الذاكرة أم فقط السورة أو الجزء أو الربع',
                    Icons.download_rounded,
                    () {},
                  ),
                  _buildSettingsTile(
                    'آخر موضع للقراءة',
                    'اختر الطريقة المناسبة لك لفتح آخر موضع للقراءة',
                    Icons.history_rounded,
                    () {},
                  ),
                  _buildToggleTile(
                    'وضع القراءة الليلية',
                    'تفعيل أو ايقاف وضع القراءة الليلية',
                    _nightMode,
                    (val) {
                      setState(() => _nightMode = val);
                      ThemeService.setThemeMode(val ? ThemeService.dark : ThemeService.light);
                    },
                  ),
                  _buildToggleTile(
                    'إظهار الخلفية الزخرفية',
                    'حدد هذا المربع لإظهار الخلفية الزخرفية في التطبيق ككل',
                    _showDecorations,
                    (val) {
                      setState(() => _showDecorations = val);
                      SettingsService.setShowDecorations(val);
                    },
                  ),
                  _buildSettingsTile(
                    'اختيار ثيمات',
                    'اختيار ثيمات لكل شاشات التطبيق',
                    Icons.palette_rounded,
                    () {},
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionHeader('إدارة الإضافات', Icons.extension_rounded),
                  _buildSocialTile(
                    'جروب القرآن (مجاني)',
                    'انضم / ادع / تابع جروب القرآن\nيمكنك من هنا الانضمام إلى جروب القرآن (مجاني) ودعوة الأصدقاء للانضمام، كذلك يمكنك متابعة الجديد في التطبيق وكيفية استعماله',
                    Icons.facebook,
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('التنبيهات', Icons.notifications_active_rounded),
                  _buildToggleTile(
                    'تنبيه التحديثات',
                    'قم بتحديد هذا الاختيار إذا أردت أن يتم تنبيهك عند وجود تحديث للتطبيق',
                    _updateNotifications,
                    (val) {
                      setState(() => _updateNotifications = val);
                      SettingsService.setUpdateNotifications(val);
                    },
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('إدارة استهلاك البطارية', Icons.battery_charging_full_rounded),
                  _buildSettingsTile(
                    'إدارة استهلاك البطارية',
                    'حتى تتجنب أي مشكلة في عمل التطبيق في الخلفية يجب إزالة أي قيود على استخدام التطبيق للبطارية',
                    Icons.battery_saver_rounded,
                    () => AppSettings.openAppSettings(type: AppSettingsType.batteryOptimization),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionHeader('الإعدادات الافتراضية', Icons.settings_backup_restore_rounded),
                  _buildSettingsTile(
                    'إعادة تعيين كافة الإعدادات',
                    'قم بتحديد هذا الاختيار إذا أردت أن يتم تنبيهك عند وجود تحديث للتطبيق',
                    Icons.refresh_rounded,
                    () async {
                      await SettingsService.resetAll();
                      _loadSettings();
                    },
                    isDestructive: true,
                  ),
                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'إعدادات',
          style: GoogleFonts.amiri(
            color: AppColors.gold,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Opacity(
          opacity: 0.05,
          child: const Icon(Icons.settings, size: 150, color: AppColors.gold),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Expanded(child: Divider(indent: 16, color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.withValues(alpha: 0.1) : AppColors.gold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDestructive ? Colors.redAccent : AppColors.gold, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                      color: isDestructive ? Colors.redAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.amiri(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.amiri(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.amiri(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.gold.withValues(alpha: 0.3),
            activeThumbColor: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTile(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1877F2), size: 30),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.amiri(
                  color: const Color(0xFF1877F2),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.amiri(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
