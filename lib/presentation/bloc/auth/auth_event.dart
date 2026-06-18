part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Subscribe to auth state changes on app start.
class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Internal: fired when the auth stream emits a new user (or null).
class _AuthUserChanged extends AuthEvent {
  final AppUser? user;
  const _AuthUserChanged(this.user);
  @override
  List<Object?> get props => [user];
}
