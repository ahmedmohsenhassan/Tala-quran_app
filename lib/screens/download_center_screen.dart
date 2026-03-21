import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/download_service.dart';
import '../utils/app_colors.dart';

class DownloadCenterScreen extends StatefulWidget {
  const DownloadCenterScreen({super.key});

  @override
  State<DownloadCenterScreen> createState() => _DownloadCenterScreenState();
}

class _DownloadCenterScreenState extends State<DownloadCenterScreen> with SingleTickerProviderStateMixin {
  final ReceivePort _port = ReceivePort();
  late TabController _tabController;
  double _usedSpaceMB = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback);
    _updateUsedSpace();
  }

  Future<void> _updateUsedSpace() async {
    final space = await DownloadService().getUsedSpaceMB();
    if (mounted) setState(() => _usedSpaceMB = space);
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    _tabController.dispose();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    bool isSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      _updateUsedSpace();
      setState(() {});
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildStorageInfo()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.gold,
                labelColor: AppColors.gold,
                unselectedLabelColor: Colors.white54,
                labelStyle: GoogleFonts.amiri(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'أجزاء المصحف', icon: Icon(Icons.menu_book_rounded)),
                  Tab(text: 'سور التلاوة', icon: Icon(Icons.audiotrack_rounded)),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMushafTab(),
            _buildAudioTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageInfo() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المساحة المستخدمة', style: GoogleFonts.amiri(color: Colors.white70)),
              Text('${_usedSpaceMB.toStringAsFixed(1)} MB', 
                style: GoogleFonts.outfit(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_usedSpaceMB / 500).clamp(0.0, 1.0), // Example 500MB limit
            backgroundColor: Colors.white10,
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text('مركز التحميل الفاخر', 
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMushafTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 30,
      itemBuilder: (context, index) => _buildJuzCard(index + 1),
    );
  }

  Widget _buildAudioTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 114,
      itemBuilder: (context, index) => _buildSurahCard(index + 1),
    );
  }

  Widget _buildJuzCard(int juzNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _buildJuzBadge(juzNumber),
          const SizedBox(width: 15),
          Expanded(
            child: Text('الجزء $juzNumber', 
              style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)),
          ),
          IconButton(
            onPressed: () => DownloadService().downloadPage(juzNumber * 20), // Proxy to a page
            icon: const Icon(Icons.download_for_offline_rounded, color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahCard(int surahNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.emerald.withValues(alpha: 0.2),
            child: Text('$surahNumber', style: const TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text('السورة $surahNumber', 
              style: GoogleFonts.amiri(color: Colors.white, fontSize: 18)),
          ),
          IconButton(
            onPressed: () => DownloadService().downloadAudio(surahNumber),
            icon: Icon(Icons.cloud_download_outlined, color: AppColors.emerald),
          ),
        ],
      ),
    );
  }

  Widget _buildJuzBadge(int number) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Center(
        child: Text('$number', 
          style: GoogleFonts.outfit(color: AppColors.gold, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
