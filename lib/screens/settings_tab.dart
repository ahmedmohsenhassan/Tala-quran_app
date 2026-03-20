import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';
import 'theme_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'premium_settings_screen.dart';
import '../services/kids_mode_service.dart';
import 'package:provider/provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.background,
              centerTitle: true,
              title: Text(
                'الإعدادات',
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle('التخصيص والمظهر'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    icon: Icons.palette_outlined,
                    title: 'تخصيص الواجهة',
                    subtitle: 'تغيير ألوان التطبيق، نوع الخط، وحجم النص',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('الإشعارات والتنبيهات'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'إعدادات الإشعارات',
                    subtitle: 'إدارة التنبيهات اليومية والتذكير بقراءة الورد',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('خصائص بريميوم (AI)'),
                  const SizedBox(height: 16),
                  Consumer<KidsModeService>(
                    builder: (context, kidsMode, child) {
                      return _buildToggleCard(
                        icon: Icons.child_care_rounded,
                        title: 'وضع الأطفال',
                        subtitle: 'واجهة مبسطة وألوان زاهية مخصصة للأطفال',
                        value: kidsMode.isKidsModeActive,
                        onChanged: (val) => kidsMode.toggleKidsMode(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('الإعدادات المتقدمة'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    icon: Icons.settings_suggest_rounded,
                    title: 'خيارات ذكية ونظام',
                    subtitle: 'تخصيص تجربة القراءة، تحسين البطارية، وإعدادات متقدمة',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PremiumSettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle('معلومات التطبيق'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(
                    icon: Icons.info_outline_rounded,
                    title: 'عن تطبيق تلا قرآن',
                    subtitle: 'الإصدار 1.0.0',
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'تلا قرآن',
                        applicationVersion: '1.0.0',
                        applicationIcon: Image.asset('assets/images/logo.png', width: 48, height: 48),
                        applicationLegalese: '© 2026 Tala Quran App',
                      );
                    },
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)), // مساحة للبار السفلي
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.amiri(
        color: AppColors.gold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.emerald, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.amiri(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.gold.withValues(alpha: 0.5), size: 16),
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
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.amiri(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.amiri(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
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
}
