import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_khatma_service.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'create_khatma_screen.dart';
import 'khatma_details_screen.dart';

class SharedKhatmaHubScreen extends StatelessWidget {
  const SharedKhatmaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final khatmaService = Provider.of<FirebaseKhatmaService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF001A16),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            _buildGlobalStatsHeader(khatmaService),
            _buildSectionHeader('ختماتي النشطة', Icons.auto_awesome_rounded),
            _buildMyKhatmasList(khatmaService),
            _buildSectionHeader('الختمات العامة', Icons.explore_rounded),
            _buildPublicKhatmasList(khatmaService),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateKhatmaScreen())),
          backgroundColor: AppColors.gold,
          icon: const Icon(Icons.add_rounded, color: Colors.black),
          label: Text('ختمة جديدة', style: GoogleFonts.notoKufiArabic(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF001A16),
      title: Text(
        'ملتقى الختمات',
        style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildGlobalStatsHeader(FirebaseKhatmaService service) {
    return SliverToBoxAdapter(
      child: StreamBuilder<Map<String, dynamic>>(
        stream: service.streamGlobalStats(),
        builder: (context, snapshot) {
          final stats = snapshot.data ?? {};
          final totalAyahs = stats['totalAyahsRead'] ?? 0;

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00241A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.public_rounded, color: AppColors.gold, size: 40),
                const SizedBox(height: 12),
                Text(
                  'إنجاز المجتمع اليوم',
                  style: GoogleFonts.amiri(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalAyahs آية',
                  style: GoogleFonts.amiri(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'نقرأ معاً، نختم معاً 🤝✨',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.amiri(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyKhatmasList(FirebaseKhatmaService service) {
    return StreamBuilder<List<SharedKhatma>>(
      stream: service.streamMyKhatmas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('لم تشترك في أي ختمة بعد.', style: TextStyle(color: Colors.white38)),
            ),
          );
        }
        final myKhatmas = snapshot.data!;
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: myKhatmas.length,
              itemBuilder: (context, index) => _buildMyKhatmaCard(context, myKhatmas[index]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPublicKhatmasList(FirebaseKhatmaService service) {
    return StreamBuilder<List<SharedKhatma>>(
      stream: service.getSharedKhatmas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        final publicKhatmas = snapshot.data ?? [];
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildPublicKhatmaCard(context, publicKhatmas[index]),
            childCount: publicKhatmas.length,
          ),
        );
      },
    );
  }

  Widget _buildMyKhatmaCard(BuildContext context, SharedKhatma khatma) {
    final currentUid = Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    final myPages = khatma.progress[currentUid] ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KhatmaDetailsScreen(khatmaId: khatma.id, title: khatma.title),
        ),
      ),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(khatma.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Text('مساهمتي:', style: TextStyle(color: Colors.white54, fontSize: 11)),
            Text('$myPages صفحة', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: khatma.totalProgress / 100, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(AppColors.gold), minHeight: 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicKhatmaCard(BuildContext context, SharedKhatma khatma) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final isParticipant = khatma.participants.contains(auth.currentUser?.uid);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KhatmaDetailsScreen(khatmaId: khatma.id, title: khatma.title),
        ),
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(khatma.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${khatma.participants.length} مشارك • ${khatma.totalProgress.toInt()}% منجز', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            if (!isParticipant)
              ElevatedButton(
                onPressed: () => FirebaseKhatmaService().joinKhatma(khatma.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                  foregroundColor: AppColors.gold,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('انضمام'),
              )
            else
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
          ],
        ),
      ),
    );
  }
}
