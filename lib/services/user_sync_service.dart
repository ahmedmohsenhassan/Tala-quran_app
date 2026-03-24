import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'bookmark_service.dart';

class UserSyncService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  static final UserSyncService _instance = UserSyncService._internal();
  factory UserSyncService() => _instance;
  UserSyncService._internal() {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  void _onAuthStateChanged(User? user) {
    if (user != null && !user.isAnonymous) {
      // User just signed in or linked account - trigger full sync
      syncFull();
    }
  }

  /// Pushes all local data to Firestore and pulls remote data
  Future<void> syncFull() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      // 1. Get local data
      final localBookmarks = await BookmarkService.getBookmarks();
      final localPageBookmarks = await BookmarkService.getPageBookmarks();
      final localLastRead = await BookmarkService.getLastRead();

      // 2. Get remote data
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        // First time syncing - push local to remote
        await userDoc.set({
          'bookmarks': localBookmarks,
          'page_bookmarks': localPageBookmarks,
          'last_read': localLastRead,
          'last_updated': FieldValue.serverTimestamp(),
        });
      } else {
        // Merge strategy: For now, we take the union of bookmarks (simple)
        // or we could use timestamps. Let's do a simple merge for bookmarks.
        final remoteData = docSnapshot.data()!;
        final remoteBookmarks = List<Map<String, dynamic>>.from(remoteData['bookmarks'] ?? []);
        final remotePageBookmarks = List<Map<String, dynamic>>.from(remoteData['page_bookmarks'] ?? []);
        final remoteLastRead = remoteData['last_read'] as Map<String, dynamic>?;

        // Merge Bookmarks (Union by surah/ayah)
        final mergedBookmarks = _mergeBookmarks(localBookmarks, remoteBookmarks);
        final mergedPageBookmarks = _mergePageBookmarks(localPageBookmarks, remotePageBookmarks);
        
        // Last Read: use the most recent one
        final mergedLastRead = _getNewestLastRead(localLastRead, remoteLastRead);

        // Update local
        // Note: We need to update BookmarkService to handle bulk updates without circular triggers
        // For now, we'll assume BookmarkService methods are safe or we'll add a silent update method
        await BookmarkService.saveAllBookmarks(mergedBookmarks);
        await BookmarkService.saveAllPageBookmarks(mergedPageBookmarks);
        if (mergedLastRead != null) {
          await BookmarkService.saveLastReadRaw(mergedLastRead);
        }

        // Update remote
        await userDoc.update({
          'bookmarks': mergedBookmarks,
          'page_bookmarks': mergedPageBookmarks,
          'last_read': mergedLastRead,
          'last_updated': FieldValue.serverTimestamp(),
        });
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('❌ Sync Failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Push a single change to Firestore (incremental)
  Future<void> pushUpdate() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final localBookmarks = await BookmarkService.getBookmarks();
      final localPageBookmarks = await BookmarkService.getPageBookmarks();
      final localLastRead = await BookmarkService.getLastRead();

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': localBookmarks,
        'page_bookmarks': localPageBookmarks,
        'last_read': localLastRead,
        'last_updated': FieldValue.serverTimestamp(),
      });
      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Incremental Sync Failed: $e');
    }
  }

  List<Map<String, dynamic>> _mergeBookmarks(List<Map<String, dynamic>> local, List<Map<String, dynamic>> remote) {
    final Map<String, Map<String, dynamic>> map = {};
    for (final b in remote) {
      map['${b['surahNumber']}:${b['ayahNumber']}'] = b;
    }
    for (final b in local) {
      map['${b['surahNumber']}:${b['ayahNumber']}'] = b;
    }
    return map.values.toList()..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  List<Map<String, dynamic>> _mergePageBookmarks(List<Map<String, dynamic>> local, List<Map<String, dynamic>> remote) {
    final Map<int, Map<String, dynamic>> map = {};
    for (final b in remote) {
      map[b['pageNumber']] = b;
    }
    for (final b in local) {
      map[b['pageNumber']] = b;
    }
    return map.values.toList()..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
  }

  Map<String, dynamic>? _getNewestLastRead(Map<String, dynamic>? local, Map<String, dynamic>? remote) {
    if (local == null) return remote;
    if (remote == null) return local;
    final localTime = DateTime.parse(local['timestamp']);
    final remoteTime = DateTime.parse(remote['timestamp']);
    return localTime.isAfter(remoteTime) ? local : remote;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
