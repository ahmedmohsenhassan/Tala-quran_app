import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_khatma_service.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'create_khatma_screen.dart';

class SharedKhatmaHubScreen extends StatelessWidget {
  const SharedKhatmaHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final khatmaService = Provider.of<FirebaseKhatmaService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF001A16),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'ملتقى الختمات',
            style: GoogleFonts.amiri(
              color: AppColors.gold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF001A16), AppColors.emerald.withValues(alpha: 0.2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: StreamBuilder<List<SharedKhatma>>(
          stream: khatmaService.getSharedKhatmas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(context);
            }

            final khatmas = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: khatmas.length,
              itemBuilder: (context, index) {
                return _buildKhatmaCard(context, khatmas[index], authService.currentUser?.uid);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateKhatmaScreen()),
            );
          },
          backgroundColor: AppColors.gold,
          icon: const Icon(Icons.add_rounded, color: Colors.black),
          label: Text(
            'ختمة جديدة',
            style: GoogleFonts.notoKufiArabic(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0x4DFFD700), size: 100), // Manually resolved withValues for const
          SizedBox(height: 16),
          Text(
            'لا توجد ختمات نشطة حالياً',
            style: TextStyle(color: Colors.white70, fontSize: 20, fontFamily: 'Amiri'),
          ),
          SizedBox(height: 8),
          Text(
            'كن أول من يبدأ ختمة جماعية!',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildKhatmaCard(BuildContext context, SharedKhatma khatma, String? currentUid) {
    final bool isParticipant = currentUid != null && khatma.participants.contains(currentUid);
    final double progress = khatma.totalProgress / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0x1A008080), // TEAL 10%
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FFD700)), // GOLD 20%
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 15,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        khatma.title,
                        style: GoogleFonts.amiri(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'بواسطة: \${khatma.adminName}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildJoinButton(context, khatma, isParticipant),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '\${khatma.participants.length} مشارك',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  '\${(progress * 100).toInt()}% منجز',
                  style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0x0DFFFFFF), // WHITE 5%
                valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context, SharedKhatma khatma, bool isParticipant) {
    return ElevatedButton(
      onPressed: isParticipant 
        ? null 
        : () async {
            final khatmaService = Provider.of<FirebaseKhatmaService>(context, listen: false);
            final authService = Provider.of<AuthService>(context, listen: false);
            if (authService.currentUser != null) {
              await khatmaService.joinKhatma(khatma.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم الانضمام للختمة بنجاح!')),
              );
            }
          },
      style: ElevatedButton.styleFrom(
        backgroundColor: isParticipant ? Colors.transparent : const Color(0x33FFD700),
        foregroundColor: AppColors.gold,
        elevation: 0,
        side: const BorderSide(color: Color(0x80FFD700)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        isParticipant ? 'مشترك' : 'انضمام',
        style: GoogleFonts.notoKufiArabic(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
