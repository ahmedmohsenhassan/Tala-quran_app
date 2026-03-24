import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firebase_khatma_service.dart';
import '../utils/app_colors.dart';
import 'package:intl/intl.dart' as intl;

class KhatmaDetailsScreen extends StatelessWidget {
  final String khatmaId;
  final String title;

  const KhatmaDetailsScreen({
    super.key,
    required this.khatmaId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final service = FirebaseKhatmaService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF001A16),
        body: StreamBuilder<SharedKhatma>(
          stream: service.streamKhatma(khatmaId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final khatma = snapshot.data!;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context, khatma),
                _buildProgressHeader(khatma),
                _buildSectionTitle('فرسان الختمة 🏆'),
                _buildLeaderboardPodium(service),
                _buildSectionTitle('آخر النشاطات 📡'),
                _buildActivityFeed(service),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, SharedKhatma khatma) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF001A16),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          khatma.title,
          style: GoogleFonts.amiri(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildProgressHeader(SharedKhatma khatma) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إنجاز المجتمع', style: GoogleFonts.amiri(color: Colors.white70)),
                    Text('${khatma.totalProgress.toInt()}%', style: GoogleFonts.outfit(color: AppColors.gold, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 40),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: khatma.totalProgress / 100,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Text(
          title,
          style: GoogleFonts.amiri(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLeaderboardPodium(FirebaseKhatmaService service) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.streamLeaderboard(khatmaId),
        builder: (context, snapshot) {
          final leaders = snapshot.data ?? [];
          if (leaders.isEmpty) return const SizedBox.shrink();

          return Container(
            height: 220,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (leaders.length > 1) _buildPodiumRank(leaders[1], '2', Colors.grey.shade400, 140),
                if (leaders.isNotEmpty) _buildPodiumRank(leaders[0], '1', AppColors.gold, 180),
                if (leaders.length > 2) _buildPodiumRank(leaders[2], '3', Colors.brown.shade400, 110),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodiumRank(Map<String, dynamic> rank, String position, Color color, double height) {
    bool isFirst = position == '1';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(position, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
            ),
            if (isFirst)
              const Positioned(
                top: -5,
                right: -5,
                child: Icon(Icons.stars_rounded, color: AppColors.gold, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${rank['pages']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const Text('صفحة', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFeed(FirebaseKhatmaService service) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: service.streamKhatmaActivity(khatmaId),
      builder: (context, snapshot) {
        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('لا يوجد نشاط بعد', style: TextStyle(color: Colors.white38)))),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final act = activities[index];
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 18)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(act['displayName'] ?? 'مشارك تالا', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('قرأ ${act['pages']} صفحات', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                    if (act['timestamp'] != null)
                      Text(
                        intl.DateFormat('HH:mm').format((act['timestamp'] as dynamic).toDate()),
                        style: const TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                  ],
                ),
              );
            },
            childCount: activities.length,
          ),
        );
      },
    );
  }
}
