part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, user, isSubmitting, error];
}
