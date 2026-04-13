import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/quran_database_service.dart';
import '../services/quran_resource_service.dart';
import '../services/tafseer_service.dart';
import '../services/bookmark_service.dart';
import '../utils/quran_page_helper.dart';
import 'ayah_share_card.dart';

class AyahInteractionBubble extends StatefulWidget {
  final int surah;
  final int ayah;
  final String translation;
  final String tafseer;
  final VoidCallback onPlay;
  final VoidCallback onClose;
  final double fontSize;

  const AyahInteractionBubble({
    super.key,
    required this.surah,
    required this.ayah,
    required this.translation,
    required this.tafseer,
    required this.onPlay,
    required this.onClose,
    this.fontSize = 17.0,
  });

  @override
  State<AyahInteractionBubble> createState() => _AyahInteractionBubbleState();
}

class _AyahInteractionBubbleState extends State<AyahInteractionBubble> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _accentGold = const Color(0xFFD4A947);
  final Color _deepGreen = const Color(0xFF031E17);
  final QuranDatabaseService _db = QuranDatabaseService();
  final QuranResourceService _resourceService = QuranResourceService();
  final TextEditingController _noteController = TextEditingController();
  
  bool _isTafseerOffline = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkOfflineStatus();
    _loadExistingNote();
  }

  Future<void> _loadExistingNote() async {
    final existingNote = await BookmarkService.getNoteForAyah(widget.surah, widget.ayah);
    if (existingNote != null && mounted) {
      setState(() {
        _noteController.text = existingNote;
      });
    }
  }

  Future<void> _checkOfflineStatus() async {
    final tafseerId = await TafseerService.getTafseerId();
    final identifier = _getTafseerIdentifier(tafseerId);
    final status = await _db.isResourceDownloaded(identifier);
    if (mounted) {
      setState(() => _isTafseerOffline = status);
    }
  }

  String _getTafseerIdentifier(int id) {
    switch (id) {
      case 16: return 'ar-tafseer-muyassar';
      case 1: return 'ar-tafsir-ibn-kathir';
      default: return 'tafseer-$id';
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return;
    
    setState(() => _isDownloading = true);
    
    final tafseerId = await TafseerService.getTafseerId();
    final name = TafseerService.availableTafseers[tafseerId] ?? 'التفسير';
    final identifier = _getTafseerIdentifier(tafseerId);

    await _resourceService.downloadTafseer(tafseerId, identifier, name);
    
    await _checkOfflineStatus();
    setState(() => _isDownloading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحميل $name بالكامل للاستخدام الأوفلاين! ✨'),
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _accentGold.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),
                
                // Tabs
                _buildTabs(),

                // Scrollable Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTafseerContent(),
                      _buildContent(widget.translation, isArabic: false),
                      _buildNoteEditor(),
                    ],
                  ),
                ),

                // Footer Actions
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                "الآية ${widget.ayah}",
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _deepGreen,
                ),
              ),
              if (_isTafseerOffline)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.offline_pin_rounded, size: 12, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      "متاح أوفلاين",
                      style: GoogleFonts.amiri(fontSize: 10, color: Colors.green.shade700),
                    ),
                  ],
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onPlay,
            icon: Icon(Icons.play_circle_fill_rounded, color: _accentGold, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: _deepGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _accentGold,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _deepGreen.withValues(alpha: 0.6),
        labelStyle: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 16),
        tabs: const [
          Tab(text: "التفسير"),
          Tab(text: "الترجمة"),
          Tab(text: "تأملات"),
        ],
      ),
    );
  }

  Widget _buildTafseerContent() {
    return Column(
      children: [
        if (!_isTafseerOffline)
          GestureDetector(
            onTap: _isDownloading ? null : _handleDownload,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  _isDownloading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))
                    : Icon(Icons.cloud_download_rounded, size: 18, color: _accentGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isDownloading ? "جاري التحميل..." : "تحميل التفسير بالكامل للاستخدام الأوفلاين",
                      style: GoogleFonts.amiri(fontSize: 13, color: _accentGold.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(child: _buildContent(widget.tafseer, isArabic: true)),
      ],
    );
  }

  Widget _buildContent(String text, {required bool isArabic}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Text(
        text,
        style: isArabic 
          ? GoogleFonts.amiri(fontSize: 18, height: 1.7, color: _deepGreen.withValues(alpha: 0.9))
          : GoogleFonts.outfit(fontSize: 16, height: 1.5, color: Colors.blueGrey.shade800),
        textAlign: isArabic ? TextAlign.right : TextAlign.left,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  Widget _buildNoteEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: _accentGold, size: 20),
                const SizedBox(width: 8),
                Text(
                  "مذكرتك القرآنية محفوظة بأمان لك",
                  style: GoogleFonts.amiri(
                    color: _accentGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: _noteController,
            maxLines: 5,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(fontSize: 16, color: _deepGreen),
            decoration: InputDecoration(
              hintText: 'اكتب تأملك الشخصي حول الآية هنا...',
              hintTextDirection: TextDirection.rtl,
              hintStyle: GoogleFonts.amiri(color: Colors.grey.shade500),
              filled: true,
              fillColor: _accentGold.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _accentGold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _accentGold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _accentGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final note = _noteController.text.trim();
              if (note.isNotEmpty) {
                final surahName = QuranPageHelper.surahNames[widget.surah - 1];
                await BookmarkService.addBookmark(
                  surahNumber: widget.surah,
                  ayahNumber: widget.ayah,
                  surahName: surahName,
                  note: note,
                );
                if (mounted) {
                  FocusScope.of(context).unfocus();
                  Navigator.pop(context); // Close popup so user can see snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم حفظ الخاطرة بنجاح'),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text(
              'حفظ الخاطرة',
              style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final surahName = QuranPageHelper.surahNames[widget.surah - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ActionButton(
            icon: Icons.copy_rounded, 
            label: "نسخ", 
            onTap: () {
              final text = 'سورة $surahName — الآية ${widget.ayah}\n~ تلا القرآن 🕌';
              Clipboard.setData(ClipboardData(text: text));
              Navigator.pop(context); // Close popup
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 تم النسخ بنجاح'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                ),
              );
            }
          ),
          _ActionButton(
            icon: Icons.share_rounded, 
            label: "مشاركة", 
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AyahShareCard(
                    ayahText: 'الآية ${widget.ayah}', 
                    surahName: surahName,
                    ayahNumber: widget.ayah,
                    surahNumber: widget.surah,
                  ),
                ),
              );
            }
          ),
          _ActionButton(
            icon: Icons.bookmark_add_rounded, 
            label: "حفظ", 
            onTap: () {
              BookmarkService.addBookmark(
                surahNumber: widget.surah,
                ayahNumber: widget.ayah,
                surahName: surahName,
              );
              Navigator.pop(context); // Close popup
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ تم حفظ الآية ${widget.ayah} من سورة $surahName'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFD4A947)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.amiri(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF031E17)),
            ),
          ],
        ),
      ),
    );
  }
}
