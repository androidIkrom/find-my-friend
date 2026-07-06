import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<AuthUserChanged>(_onUserChanged);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);

    _userSubscription = _authRepository.authStateChanges().listen(
          (user) => add(AuthUserChanged(user)),
        );
  }

  final AuthRepository _authRepository;
  late final StreamSubscription<User?> _userSubscription;

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    if (event.user == null) {
      emit(const AuthState.unauthenticated());
    } else {
      emit(AuthState.authenticated(event.user!.uid));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signIn(email: event.email, password: event.password);
    } on FirebaseAuthException catch (e) {
      emit(AuthState.unauthenticated(_friendlyMessage(e.code)));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signUp(email: event.email, password: event.password);
    } on FirebaseAuthException catch (e) {
      emit(AuthState.unauthenticated(_friendlyMessage(e.code)));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Choose a password with at least 6 characters.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }
}
