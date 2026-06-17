import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/app_user.dart';
import '../../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _userSub;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthGoogleSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authRepository.initialize();
    _userSub?.cancel();
    _userSub = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.user,
        isSubmitting: false,
      ));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    try {
      await _authRepository.signInWithGoogle();
      // The auth stream will emit the authenticated user and drive navigation.
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: 'Sign-in failed. Please try again.',
      ));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }
}
