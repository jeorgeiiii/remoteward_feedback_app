import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// The three outcomes the export gate cares about.
enum AuthOutcome { success, failed, lockNotSet }

/// Gates sensitive actions (the CSV export) behind device authentication.
/// Accepts fingerprint OR device PIN / pattern / password (biometricOnly:false),
/// and reports when no screen lock is enrolled so the UI can guide the user.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  Future<AuthOutcome> authenticate({
    String reason = 'Verify it\'s you to export feedback data',
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // fingerprint OR PIN / pattern / password
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok ? AuthOutcome.success : AuthOutcome.failed;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return AuthOutcome.lockNotSet;
      }
      return AuthOutcome.failed;
    } catch (_) {
      return AuthOutcome.failed;
    }
  }
}