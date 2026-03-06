import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surahs.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import 'mushaf_viewer_screen.dart';

/// شاشة البحث في السور
/// Search screen for finding surahs
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = List.from(surahs);
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = List.from(surahs);
      } else {
        _filteredSurahs = surahs.where((surah) {
          final name = surah['name'].toString().toLowerCase();
          final englishName = surah['english_name'].toString().toLowerCase();
          final number = surah['number'].toString();
          final q = query.toLowerCase();
          return name.contains(q) || englishName.contains(q) || number == q;
        }).toList();
      }
    });
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
            'البحث',
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
            // حقل البحث - Search field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 18),
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة...',
                  hintStyle: GoogleFonts.amiri(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.textMuted),
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
                    borderSide: BorderSide(color: AppColors.gold.withOpacity(0.5)),
                  ),
                ),
              ),
            ),

            // عدد النتائج - Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${_filteredSurahs.length} سورة',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),

            // نتائج البحث - Search results
            Expanded(
              child: _filteredSurahs.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: GoogleFonts.amiri(
                          color: AppColors.textMuted,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = _filteredSurahs[index];
                        return SurahCard(
                          number: surah['number'],
                          name: surah['name'],
                          englishName: surah['english_name'],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MushafViewerScreen(
                                  initialPage: QuranPageHelper.getPageForSurah(surah['number']),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
