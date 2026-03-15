import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/theme_service.dart';
import '../services/translation_service.dart';
import '../utils/app_colors.dart';
import '../main.dart'; // للوصول لـ themeNotifier

/// شاشة تخصيص المظهر الشاملة (Theme Settings)
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _currentThemeMode = ThemeMode.dark.name;
  String _currentColorTheme = ThemeService.colorEmerald;
  String _currentFontTheme = ThemeService.fontAmiri;
  String _currentMushafTheme = ThemeService.mushafClassic;
  double _currentFontSizeMultiplier = 1.0;
  bool _isTranslationEnabled = false;
  int _currentTranslationLang = TranslationService.langEnglish;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final mode = await ThemeService.getThemeMode();
    final color = await ThemeService.getThemeColor();
    final font = await ThemeService.getThemeFont();
    final mushafTheme = await ThemeService.getMushafTheme();
    final fontSize = await ThemeService.getFontSizeMultiplier();
    final isTransEnabled = await TranslationService.isTranslationEnabled();
    final transLang = await TranslationService.getTranslationLanguage();

    if (mounted) {
      setState(() {
        _currentThemeMode = mode;
        _currentColorTheme = color;
        _currentFontTheme = font;
        _currentMushafTheme = mushafTheme;
        _currentFontSizeMultiplier = fontSize;
        _isTranslationEnabled = isTransEnabled;
        _currentTranslationLang = transLang;
        _isLoading = false;
      });
    }
  }

  void _onTranslationToggle(bool value) async {
    setState(() => _isTranslationEnabled = value);
    await TranslationService.setTranslationEnabled(value);
  }

  void _onTranslationLangChanged(int langId) async {
    setState(() => _currentTranslationLang = langId);
    await TranslationService.setTranslationLanguage(langId);
  }

  void _onModeChanged(String newMode) async {
    setState(() => _currentThemeMode = newMode);
    await ThemeService.setThemeMode(newMode);
    
    // update global app theme
    if (newMode == ThemeService.light) {
      themeNotifier.value = ThemeMode.light;
    } else if (newMode == ThemeService.system) {
      themeNotifier.value = ThemeMode.system;
    } else {
      themeNotifier.value = ThemeMode.dark;
    }
  }

  void _onColorChanged(String newColor) async {
    setState(() => _currentColorTheme = newColor);
    await ThemeService.setThemeColor(newColor);
    
    // update AppColors values
    AppColors.applyColorTheme(newColor);
    
    // update global color notifier to trigger app-wide rebuild
    colorNotifier.value = newColor;
  }

  void _onFontChanged(String newFont) async {
    setState(() => _currentFontTheme = newFont);
    await ThemeService.setThemeFont(newFont);
    fontNotifier.value = newFont;
  }

  void _onMushafThemeChanged(String newTheme) async {
    setState(() => _currentMushafTheme = newTheme);
    await ThemeService.setMushafTheme(newTheme);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

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
            'تخصيص المظهر',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Theme Mode (Dark/Light/System)
            _buildSectionTitle('وضع الشاشة', Icons.brightness_6_rounded),
            const SizedBox(height: 16),
            _buildModeSelector(),

            const SizedBox(height: 32),

            // 1.5. Mushaf Premium Themes (New Selection)
            _buildSectionTitle('المظهر (الثيم)', Icons.auto_awesome_rounded),
            const SizedBox(height: 16),
            _buildMushafThemeSelector(),

            const SizedBox(height: 32),

            // 2. Color Palette
            _buildSectionTitle('الألوان الأساسية', Icons.palette_rounded),
            const SizedBox(height: 16),
            _buildColorSelectors(),

            const SizedBox(height: 32),

            // 3. Fonts
            _buildSectionTitle('الخط القرآني المفضل', Icons.text_fields_rounded),
            const SizedBox(height: 16),
            _buildFontSelectors(),
            
            const SizedBox(height: 32),
            
            // 4. Font Size
            _buildSectionTitle('حجم الخط', Icons.format_size_rounded),
            const SizedBox(height: 16),
            _buildFontSizeSlider(),
            
            const SizedBox(height: 32),
            
            // 5. Translations
            _buildSectionTitle('الترجمة الإضافية', Icons.translate_rounded),
            const SizedBox(height: 16),
            _buildTranslationSettings(),
            
            const SizedBox(height: 32),
            
            // Preview
            _buildSectionTitle('معاينة', Icons.visibility_rounded),
            const SizedBox(height: 16),
            _buildPreviewCard(),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.amiri(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationSettings() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: SwitchListTile(
            title: Text(
              'إظهار الترجمة أسفل الآيات',
              style: GoogleFonts.amiri(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'ينطبق ذلك على شاشة تلاوة السور',
              style: GoogleFonts.amiri(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            activeThumbColor: AppColors.gold,
            value: _isTranslationEnabled,
            onChanged: _onTranslationToggle,
            secondary: const Icon(Icons.language_rounded, color: AppColors.gold),
          ),
        ),
        if (_isTranslationEnabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSelectorCard(
                  title: 'English (Saheeh Intl.)',
                  icon: Icons.g_translate_rounded,
                  isSelected: _currentTranslationLang == TranslationService.langEnglish,
                  onTap: () => _onTranslationLangChanged(TranslationService.langEnglish),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectorCard(
                  title: 'Urdu (Maududi)',
                  icon: Icons.g_translate_rounded,
                  isSelected: _currentTranslationLang == TranslationService.langUrdu,
                  onTap: () => _onTranslationLangChanged(TranslationService.langUrdu),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectorCard(
            title: 'داكن',
            icon: Icons.nightlight_round,
            isSelected: _currentThemeMode == ThemeService.dark,
            onTap: () => _onModeChanged(ThemeService.dark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorCard(
            title: 'فاتح',
            icon: Icons.wb_sunny_rounded,
            isSelected: _currentThemeMode == ThemeService.light,
            onTap: () => _onModeChanged(ThemeService.light),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectorCard(
            title: 'تلقائي',
            icon: Icons.settings_suggest_rounded,
            isSelected: _currentThemeMode == ThemeService.system,
            onTap: () => _onModeChanged(ThemeService.system),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelectors() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // Emerald
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40 - 24) / 3, // 3 columns max
          child: _buildColorCard(
            colorValue: const Color(0xFF03251D), // Deep Emerald
            label: 'زمردي',
            isSelected: _currentColorTheme == ThemeService.colorEmerald,
            onTap: () => _onColorChanged(ThemeService.colorEmerald),
          ),
        ),
        
        // Burgundy
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
          child: _buildColorCard(
            colorValue: const Color(0xFF1F0E12), // Deep Burgundy
            label: 'عنابي',
            isSelected: _currentColorTheme == ThemeService.colorBurgundy,
            onTap: () => _onColorChanged(ThemeService.colorBurgundy),
          ),
        ),
        
        // Blue
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
          child: _buildColorCard(
            colorValue: const Color(0xFF0A1526), // Deep Navy
            label: 'نيلي',
            isSelected: _currentColorTheme == ThemeService.colorBlue,
            onTap: () => _onColorChanged(ThemeService.colorBlue),
          ),
        ),

        // Gold
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
          child: _buildColorCard(
            colorValue: const Color(0xFF33270F), // Deep Gold
            label: 'ذهبي',
            isSelected: _currentColorTheme == ThemeService.colorGold,
            onTap: () => _onColorChanged(ThemeService.colorGold),
          ),
        ),

        // Monochrome
        SizedBox(
          width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
          child: _buildColorCard(
            colorValue: const Color(0xFF1A1A1A), // Charcoal
            label: 'داكن جداً',
            isSelected: _currentColorTheme == ThemeService.colorMonochrome,
            onTap: () => _onColorChanged(ThemeService.colorMonochrome),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSelectors() {
    return Column(
      children: [
        _buildFontOptionCard('أميري (Amiri)', ThemeService.fontAmiri, (t) => GoogleFonts.amiri().merge(t)),
        const SizedBox(height: 10),
        _buildFontOptionCard('خط المصحف الكلاسيكي (عثماني)', ThemeService.fontUthmanic, (TextStyle t) => t.copyWith(fontFamily: 'Uthmanic')),
        const SizedBox(height: 10),
        _buildFontOptionCard('خط إندو-باك (مجيّدي)', ThemeService.fontIndopak, (TextStyle t) => t.copyWith(fontFamily: 'IndoPak')),
        const SizedBox(height: 10),
        _buildFontOptionCard('نسخ (Naskh)', ThemeService.fontNaskh, (t) => GoogleFonts.notoNaskhArabic().merge(t)),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ع',
                style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 16),
              ),
              Text(
                'ع',
                style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 32),
              ),
            ],
          ),
          Slider(
            value: _currentFontSizeMultiplier,
            min: 0.8,
            max: 2.5,
            divisions: 17,
            activeColor: AppColors.gold,
            inactiveColor: AppColors.gold.withValues(alpha: 0.2),
            onChanged: (val) {
              setState(() => _currentFontSizeMultiplier = val);
              fontNotifier.value = _currentFontTheme; // Trigger minor rebuild just in case, but fontSizeNotifier is better 
              fontSizeNotifier.value = val;
            },
            onChangeEnd: (val) async {
              await ThemeService.setFontSizeMultiplier(val);
            },
          ),
          Text(
            '${(_currentFontSizeMultiplier * 100).toInt()}%',
            style: GoogleFonts.outfit(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.amiri(
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCard({
    required Color colorValue,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorValue,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.gold, size: 20)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.amiri(
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontOptionCard(String label, String fontValue, TextStyle Function(TextStyle) fontStyle) {
    final isSelected = _currentFontTheme == fontValue;
    
    return GestureDetector(
      onTap: () => _onFontChanged(fontValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.gold : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: fontStyle(
                TextStyle(
                  color: isSelected ? AppColors.gold : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviewCard() {
    String fontFamily;
    if (_currentFontTheme == ThemeService.fontNaskh) {
      fontFamily = 'Noto Naskh Arabic';
    } else if (_currentFontTheme == ThemeService.fontUthmanic) {
      fontFamily = 'Uthmanic';
    } else if (_currentFontTheme == ThemeService.fontIndopak) {
      fontFamily = 'IndoPak';
    } else {
      fontFamily = 'Amiri';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.emeraldLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
            style: TextStyle(
              fontFamily: fontFamily,
              color: AppColors.emeraldLight,
              fontSize: 24 * _currentFontSizeMultiplier,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ﴿١﴾ الرَّحْمَنِ الرَّحِيمِ ﴿٢﴾ مَالِكِ يَوْمِ الدِّينِ ﴿٣﴾ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ ﴿٤﴾',
            style: TextStyle(
              fontFamily: fontFamily,
              color: AppColors.textPrimary,
              fontSize: 20 * _currentFontSizeMultiplier,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMushafThemeSelector() {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMushafThemeCard(
            title: 'كلاسيكي',
            theme: ThemeService.mushafClassic,
            primaryColor: const Color(0xFF03251D),
            secondaryColor: const Color(0xFFFDF5E6),
            isPremium: false,
          ),
          const SizedBox(width: 16),
          _buildMushafThemeCard(
            title: 'المذهّب',
            theme: ThemeService.mushafPremium,
            primaryColor: const Color(0xFF33270F),
            secondaryColor: const Color(0xFFFFD700),
            isPremium: true,
            badge: 'مميز',
          ),
          const SizedBox(width: 16),
          _buildMushafThemeCard(
            title: 'ليلي مريح',
            theme: ThemeService.mushafDark,
            primaryColor: const Color(0xFF05110E),
            secondaryColor: const Color(0xFF1E3516),
            isPremium: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMushafThemeCard({
    required String title,
    required String theme,
    required Color primaryColor,
    required Color secondaryColor,
    bool isPremium = false,
    String? badge,
  }) {
    final bool isSelected = _currentMushafTheme == theme;

    return GestureDetector(
      onTap: () => _onMushafThemeChanged(theme),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            // Preview Image / Icon
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                      ),
                      border: Border.all(
                        color: secondaryColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: isPremium ? AppColors.gold : Colors.white24,
                        size: 40,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 15,
                      right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Color(0xFF634D00), size: 10),
                            const SizedBox(width: 4),
                            Text(
                              badge,
                              style: GoogleFonts.amiri(
                                color: const Color(0xFF634D00),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Text and Button
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                const Color(0xFFFFD700),
                                const Color(0xFFD4A947),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        isSelected ? 'استخدم' : 'احصل',
                        style: GoogleFonts.amiri(
                          color: isSelected ? const Color(0xFF4A3B00) : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
