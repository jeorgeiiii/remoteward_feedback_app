import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Wraps Firebase Auth + Google Sign-In so the rest of the app depends on a
/// clean interface (`AppUser`) instead of the plugin types directly.
///
/// IMPORTANT: targets google_sign_in ^7.x, which replaced the old
/// `GoogleSignIn().signIn()` flow with a singleton + `initialize()` +
/// `authenticate()`. Authentication (identity) and authorization (scopes/
/// access token) are now two separate steps.
class AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  bool _initialized = false;

  /// Must be awaited exactly once before any sign-in attempt.
  /// Call this during app bootstrap.
  Future<void> initialize() async {
    if (_initialized) return;
    // serverClientId is your Firebase project's *Web* OAuth client ID.
    // Required on Android so Firebase accepts the returned idToken.
    await GoogleSignIn.instance.initialize(
      serverClientId: '74253352157-q9npbbhvkgi1erbei8j7o3omqfsfoj06.apps.googleusercontent.com',
    );
    _initialized = true;
  }

  /// Emits the current owner whenever auth state changes (sign in / out).
  Stream<AppUser?> get authStateChanges =>
      _firebaseAuth.authStateChanges().map(_mapFirebaseUser);

  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  Future<AppUser?> signInWithGoogle() async {
    await initialize();

    // 1. Authenticate (identity) — shows the account picker / Credential
    //    Manager sheet. Throws GoogleSignInException on cancel/error.
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // 2. Get the id token from the authentication result.
    final idToken = googleUser.authentication.idToken;

    // 3. (Optional) Authorize scopes to obtain an access token. Firebase only
    //    strictly needs the idToken on Android, but we request it for parity.
    String? accessToken;
    try {
      final authz = await googleUser.authorizationClient
          .authorizeScopes(<String>['email', 'profile']);
      accessToken = authz.accessToken;
    } catch (_) {
      // Scope authorization can be skipped; idToken alone is enough for sign-in.
    }

    // 4. Build a Firebase credential and sign in.
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    final result = await _firebaseAuth.signInWithCredential(credential);
    return _mapFirebaseUser(result.user);
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
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
