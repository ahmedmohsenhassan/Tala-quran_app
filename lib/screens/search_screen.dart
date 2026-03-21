import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/surah_metadata.dart';
import '../utils/app_colors.dart';
import '../utils/quran_page_helper.dart';
import '../widgets/surah_card.dart';
import '../services/quran_text_service.dart';
import '../services/search_database_service.dart';
import 'mushaf_viewer_screen.dart';

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
      if (!_isLoading && _ayahResults.isEmpty) setState(() => _isLoading = true);
      
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
                  title: _buildHighlightedText(ayah['text'], _searchController.text),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'سورة ${ayah['surahNumber']} - آية ${ayah['verseNumber']}',
                      style:
                          const TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    final surahNum = int.parse(ayah['surahNumber']);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MushafViewerScreen(
                          initialPage: QuranPageHelper.getPageForSurah(surahNum),
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

  /// 🎨 مُبرز الكلمات الذهبي (Tashkeel-Agnostic Word Highlighter)
  Widget _buildHighlightedText(String uthmaniText, String query) {
    if (query.isEmpty) {
      return Text(
        uthmaniText,
        style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 18),
        textAlign: TextAlign.right,
      );
    }

    final queryClean = SearchDatabaseService().removeTashkeel(query.trim());
    if (queryClean.isEmpty) {
      return Text(
        uthmaniText,
        style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 18),
        textAlign: TextAlign.right,
      );
    }

    final words = uthmaniText.split(' ');
    final List<TextSpan> spans = [];

    for (var i = 0; i < words.length; i++) {
      final String word = words[i];
      final String wordClean = SearchDatabaseService().removeTashkeel(word);

      // Check if word contains the query, or query contains the word (robust partial matching)
      if (wordClean.isNotEmpty && (wordClean.contains(queryClean) || queryClean.contains(wordClean))) {
        spans.add(TextSpan(
          text: '$word ',
          style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.bold),
        ));
      } else {
        spans.add(TextSpan(
          text: '$word ',
          style: GoogleFonts.amiri(color: AppColors.textPrimary, fontSize: 18),
        ));
      }
    }

    return RichText(
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }
}
