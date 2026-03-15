import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surah_metadata.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import '../services/quran_text_service.dart';
import 'mushaf_viewer_screen.dart';
import 'surah_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final QuranTextService _quranService = QuranTextService();

  List<Map<String, dynamic>> _filteredSurahs = [];
  List<Map<String, dynamic>> _ayahResults = [];
  bool _isAyahSearch = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _filteredSurahs = List.from(surahMetadata);
  }

  void _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredSurahs = List.from(surahMetadata);
        _ayahResults = [];
        _isLoading = false;
      });
      return;
    }

    if (!_isAyahSearch) {
      setState(() {
        _filteredSurahs = surahMetadata.where((surah) {
          final name = surah['name'].toString().toLowerCase();
          final englishName = surah['englishName'].toString().toLowerCase();
          final number = surah['number'].toString();
          final q = query.toLowerCase();
          return name.contains(q) || englishName.contains(q) || number == q;
        }).toList();
      });
    } else {
      setState(() => _isLoading = true);
      final results = await _quranService.searchAyahs(query);
      if (mounted) {
        setState(() {
          _ayahResults = results;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          title: Text(
            'البحث المتقدم',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // تختار نوع البحث - Search Type Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTypeButton('السور', !_isAyahSearch),
                    _buildTypeButton('الآيات', _isAyahSearch),
                  ],
                ),
              ),
            ),

            // حقل البحث - Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: GoogleFonts.amiri(
                    color: AppColors.textPrimary, fontSize: 18),
                decoration: InputDecoration(
                  hintText:
                      _isAyahSearch ? 'ابحث عن نص آية...' : 'ابحث عن سورة...',
                  hintStyle: GoogleFonts.amiri(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ),

            if (_isAyahSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _isLoading
                      ? 'جاري البحث...'
                      : '${_ayahResults.length} نتيجة بحث',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${_filteredSurahs.length} سورة',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),

            const SizedBox(height: 8),

            // نتائج البحث - Search results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.gold))
                  : (!_isAyahSearch ? _buildSurahList() : _buildAyahList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String title, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isAyahSearch = title == 'الآيات';
            _onSearch(_searchController.text);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.amiri(
                color: isSelected ? Colors.black : AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return _filteredSurahs.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: _filteredSurahs.length,
            itemBuilder: (context, index) {
              final surah = _filteredSurahs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SurahCard(
                  number: surah['number'],
                  name: surah['name'],
                  revelationType: surah['revelationType'],
                  totalAyahs: surah['totalAyahs'],
                  pageNumber: surah['pageNumber'],
                  onTap: () => _showReadModeDialog(context, surah),
                ),
              );
            },
          );
  }

  Widget _buildAyahList() {
    return _ayahResults.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            itemCount: _ayahResults.length,
            itemBuilder: (context, index) {
              final ayah = _ayahResults[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  title: Text(
                    ayah['text'],
                    style: GoogleFonts.amiri(
                        color: AppColors.textPrimary, fontSize: 18),
                    textAlign: TextAlign.right,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'سورة ${ayah['surahNumber']} - آية ${ayah['verseNumber']}',
                      style:
                          const TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    // العثور على اسم السورة من القائمة المعرفة مسبقاً
                    final surahNum = int.parse(ayah['surahNumber']);
                    String surahName = "سورة $surahNum";
                    try {
                      final surahData = surahMetadata.firstWhere((s) => s['number'] == surahNum);
                      surahName = surahData['name'] ?? surahName;
                    } catch (_) {}

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahDetailScreen(
                          surahNumber: surahNum,
                          surahName: surahName,
                          highlightedAyah: int.parse(ayah['verseNumber']),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'لا توجد نتائج',
        style: GoogleFonts.amiri(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }

  void _showReadModeDialog(BuildContext context, Map<String, dynamic> surah) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            'اختر طريقة القراءة',
            style: GoogleFonts.amiri(
                color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(Icons.menu_book, 'قراءة من المصحف',
                  'عرض صفحات مصورة (تحتاج تحميل)', () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MushafViewerScreen(
                              initialPage: QuranPageHelper.getPageForSurah(
                                  surah['number']),
                            )));
              }),
              const Divider(color: Colors.white10),
              _buildDialogOption(Icons.text_format, 'قراءة نصية',
                  'عرض آيات مكتوبة (تعمل دائماً)', () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SurahDetailScreen(
                              surahNumber: surah['number'],
                              surahName: surah['name'],
                            )));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption(
      IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(sub,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      onTap: onTap,
    );
  }
}
