import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// خدمة مزامنة بيانات السور مع فايربيز — Firestore Surah Sync Service
class FirestoreSyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// مزامنة قائمة السور من ملف JSON المحلي إلى فايربيز
  /// Syncs the surah list from local JSON to Firestore
  Future<void> syncSurahsToFirestore() async {
    debugPrint('📡 Starting Firestore Surah Sync check...');
    try {
      // 1. Check if already synced
      final existing = await _db.collection('surahs').limit(1).get();
      if (existing.docs.isNotEmpty) {
        debugPrint('📡 [ALREADY SYNCED]: Surah list found in Firestore. Skipping migration.');
        return;
      }

      debugPrint('📡 [MIGRATION STARTING]: DB is empty. Fetching local JSON...');
      
      // 2. Load local JSON
      final String response = await rootBundle.loadString('assets/data/surahs.json');
      final List<dynamic> data = await compute<String, List<dynamic>>((String rest) => json.decode(rest), response);

      debugPrint('📡 [UPLOADING]: Writing ${data.length} surahs via Batch...');

      // 3. Batch write
      final WriteBatch batch = _db.batch();
      for (var surah in data) {
        final docRef = _db.collection('surahs').doc(surah['id'].toString());
        batch.set(docRef, {
          'id': surah['id'],
          'name': surah['name'],
          'englishName': surah['englishName'],
          'syncDate': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ [SUCCESS]: All surahs synced to Firestore.');
    } catch (e) {
      debugPrint('❌ [SYNC FAILED]: Error writing to Firestore: $e');
      debugPrint('👉 TIP: Check if Firestore Rules allow writes and API is enabled.');
    }
  }

  /// الحصول على قائمة السور من فايربيز (للاستخدام المستقبلي)
  /// Fetch surah list from Firestore
  Stream<List<Map<String, dynamic>>> getSurahsStream() {
    return _db.collection('surahs').orderBy('id').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}
