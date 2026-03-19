import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.fontSize = 16.0,
  });

  @override
  State<AyahInteractionBubble> createState() => _AyahInteractionBubbleState();
}

class _AyahInteractionBubbleState extends State<AyahInteractionBubble> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _accentGold = const Color(0xFFD4A947);
  final Color _deepGreen = const Color(0xFF031E17);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          // Removed hardcoded height to allow for dynamic content
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _accentGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with controls
              _buildHeader(),
              
              const Divider(height: 1),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: _accentGold,
                labelColor: _deepGreen,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: "التفسير"),
                  Tab(text: "المعنى"),
                ],
              ),

              // Tab Content
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScrollableContent(widget.tafseer),
                    _buildScrollableContent(widget.translation),
                  ],
                ),
              ),

              // Bottom Actions
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _deepGreen.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
          ),
          Text(
            "الآية ${widget.ayah}",
            style: GoogleFonts.amiri(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _deepGreen,
            ),
          ),
          IconButton(
            onPressed: widget.onPlay,
            icon: Icon(Icons.play_circle_fill_rounded, color: _accentGold, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        text,
        style: GoogleFonts.amiri(
          fontSize: widget.fontSize,
          height: 1.6,
          color: Colors.black87,
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(icon: Icons.copy_rounded, label: "نسخ", onTap: () {}),
          _ActionButton(icon: Icons.share_rounded, label: "مشاركة", onTap: () {}),
          _ActionButton(icon: Icons.bookmark_border_rounded, label: "حفظ", onTap: () {}),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.green.shade800),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.amiri(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
