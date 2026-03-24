import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  late final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final bool isFirebaseReady;

  User? get currentUser => isFirebaseReady ? _auth.currentUser : null;
  bool get isAuthenticated => currentUser != null;

  AuthService({this.isFirebaseReady = true}) {
    if (isFirebaseReady) {
      _auth = FirebaseAuth.instance;
      _initSilentAuth();
    }
  }

  /// Silently logins the user anonymously if they aren't logged in at all.
  Future<void> _initSilentAuth() async {
    if (!_isInitialized) return;

    // Wait for the auth state to resolve first
    await _auth.authStateChanges().first;
    
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
        debugPrint('👻 Anonymous User Created: ${_auth.currentUser?.uid}');
      } catch (e) {
        debugPrint('⚠️ Silent Auth Failed: $e');
      }
    }
  }

  bool get _isInitialized => isFirebaseReady;

  /// Upgrade anonymous account to Google account
  Future<UserCredential?> linkWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link with existing anonymous account
      final userCredential = await _auth.currentUser?.linkWithCredential(credential);
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('❌ Account Linking Failed: $e');
      rethrow;
    }
  }

  /// Direct Google Sign In (if not linking)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google Sign In Failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    notifyListeners();
  }
}
