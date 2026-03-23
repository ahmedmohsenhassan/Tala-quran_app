import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  late final FirebaseAuth _auth;
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
    // Wait for the auth state to resolve first
    await _auth.authStateChanges().first;
    
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
        debugPrint('👻 Anonymous User Created: \${_auth.currentUser?.uid}');
      } catch (e) {
        debugPrint('⚠️ Silent Auth Failed: \$e');
      }
    }
  }
}
