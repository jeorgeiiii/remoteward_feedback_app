import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Thrown when a verified Google account is not on the approved allowlist.
class NotApprovedException implements Exception {
  const NotApprovedException();
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        // ✅ Web Client ID (type 3) – passed directly to GoogleSignIn constructor
        _googleSignIn = GoogleSignIn(
          clientId:
              '74253352157-q9npbbhvkgi1erbei8j7o3omqfsfoj06.apps.googleusercontent.com',
        );

  /// ✅ Only these accounts may use the app. Compared in lowercase.
  static const _allowedEmails = <String>{
    'liberlismtor@gmail.com',
    'princemehra3666@gmail.com',
    'info@remoteward.com',
  };

  /// Emits the current owner whenever auth state changes (sign in / out).
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_mapFirebaseUser);

  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  /// No-op initializer kept for compatibility with older call sites.
  Future<void> initialize() async {}

  /// Signs in with Google using the web‑based OAuth flow.
  /// This bypasses the SHA‑256 validation required by Android's Credential Manager.
  Future<AppUser?> signInWithGoogle() async {
    // 🔥 Use .signIn() instead of .authenticate() – forces web flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'You cancelled the sign-in.',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken, // ✅ Access token is optional, no error
    );

    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;

    // 🔐 ALLOWLIST CHECK – Now ACTIVE
    final email = (user?.email ?? '').toLowerCase();
    if (!_allowedEmails.contains(email)) {
      await signOut(); // reject and sign back out
      throw const NotApprovedException();
    }

    return _mapFirebaseUser(user);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      name: user.displayName ?? 'Device Owner',
      email: user.email ?? '',
      photoUrl: user.photoURL,
    );
  }
}