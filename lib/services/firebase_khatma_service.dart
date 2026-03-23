import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// نموذج الختمة المشتركة — Shared Khatma Model
class SharedKhatma {
  final String id;
  final String title;
  final String creatorId;
  final List<String> participants;
  final List<String> onlineParticipants; // 📡 New: Track who is currently online
  final Map<String, int> progress; // Map of uid to pages read
  final DateTime createdAt;
  final bool isPrivate;

  SharedKhatma({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.participants,
    required this.onlineParticipants,
    required this.progress,
    required this.createdAt,
    this.isPrivate = false,
  });

  /// 📊 Calculate total community progress percentage
  double get totalProgress {
    if (progress.isEmpty) return 0.0;
    // For a 604-page Quran, let's assume goal is 604 * participants
    int totalPagesRead = progress.values.fold(0, (acc, val) => acc + val);
    int goal = 604 * participants.length;
    return (totalPagesRead / goal) * 100;
  }

  /// 👤 Get name of the admin (first participant for now or from dedicated field)
  String get adminName => "مستخدم تالا"; // Placeholder until we have user profiles

  factory SharedKhatma.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return SharedKhatma(
      id: doc.id,
      title: data['title'] ?? '',
      creatorId: data['creatorId'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      onlineParticipants: List<String>.from(data['onlineParticipants'] ?? []),
      progress: Map<String, int>.from(data['progress'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPrivate: data['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'creatorId': creatorId,
      'participants': participants,
      'onlineParticipants': onlineParticipants,
      'progress': progress,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
    };
  }
}

/// خدمة الختمة التشاركية عبر فايربيز — Firebase Collaborative Khatma Service
class FirebaseKhatmaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إنشاء ختمة جديدة — Create a new shared Khatma
  Future<String?> createSharedKhatma(String title, {bool isPrivate = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ [CREATE FAILED]: User is null.');
        return null;
      }

      final doc = await _db.collection('shared_khatmas').add({
        'title': title,
        'creatorId': user.uid,
        'participants': [user.uid],
        'progress': {user.uid: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'isPrivate': isPrivate,
      });

      debugPrint('✅ [CREATE SUCCESS]: Khatma ID: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ [CREATE FAILED]: Error adding to Firestore: $e');
      rethrow; // Pass to UI for SnackBar
    }
  }

  /// الانضمام لختمة — Join an existing Khatma
  Future<void> joinKhatma(String khatmaId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('shared_khatmas').doc(khatmaId).update({
      'participants': FieldValue.arrayUnion([user.uid]),
      'progress.\${user.uid}': 0,
    });
  }

  /// تحديث التقدم — Update user progress in a khatma
  Future<void> updateProgress(String khatmaId, int pagesRead) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('shared_khatmas').doc(khatmaId).update({
      'progress.\${user.uid}': pagesRead,
    });
  }

  /// الحصول على الختمات المشترك بها — Stream of khatmas the user is part of
  Stream<List<SharedKhatma>> streamMyKhatmas() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('shared_khatmas')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SharedKhatma.fromFirestore(doc)).toList());
  }

  /// الحصول على كل الختمات العامة — Stream of all public khatmas
  Stream<List<SharedKhatma>> getSharedKhatmas() {
    return _db
        .collection('shared_khatmas')
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SharedKhatma.fromFirestore(doc)).toList());
  }

  /// البحث عن الختمات العامة — Search public khatmas
  Future<List<SharedKhatma>> searchPublicKhatmas() async {
    final query = await _db
        .collection('shared_khatmas')
        .where('isPrivate', isEqualTo: false)
        .limit(10)
        .get();

    return query.docs.map((doc) => SharedKhatma.fromFirestore(doc)).toList();
  }

  /// تحديث التواجد المباشر — Update live presence
  Future<void> updatePresence(String khatmaId, bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (isOnline) {
      await _db.collection('shared_khatmas').doc(khatmaId).update({
        'onlineParticipants': FieldValue.arrayUnion([user.uid]),
      });
    } else {
      await _db.collection('shared_khatmas').doc(khatmaId).update({
        'onlineParticipants': FieldValue.arrayRemove([user.uid]),
      });
    }
  }

  /// الحصول على ختمة محددة بالبث المباشر — Stream a specific khatma
  Stream<SharedKhatma> streamKhatma(String khatmaId) {
    return _db
        .collection('shared_khatmas')
        .doc(khatmaId)
        .snapshots()
        .map((doc) => SharedKhatma.fromFirestore(doc));
  }
}
