import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:find_my_friend/auth/auth_bloc.dart';
import 'package:find_my_friend/auth/auth_event.dart';
import 'package:find_my_friend/auth/auth_repository.dart';
import 'package:find_my_friend/auth/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository authRepository;
  late StreamController<User?> userController;

  setUp(() {
    authRepository = MockAuthRepository();
    userController = StreamController<User?>.broadcast();
    when(() => authRepository.authStateChanges())
        .thenAnswer((_) => userController.stream);
  });

  tearDown(() => userController.close());

  test('initial state is unknown', () {
    final bloc = AuthBloc(authRepository: authRepository);
    expect(bloc.state, const AuthState.unknown());
    bloc.close();
  });

  blocTest<AuthBloc, AuthState>(
    'emits unauthenticated when the auth stream emits a null user',
    build: () => AuthBloc(authRepository: authRepository),
    act: (bloc) => userController.add(null),
    expect: () => [const AuthState.unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'emits authenticated with the uid when the auth stream emits a user',
    build: () => AuthBloc(authRepository: authRepository),
    act: (bloc) {
      final user = MockUser();
      when(() => user.uid).thenReturn('user-123');
      userController.add(user);
    },
    expect: () => [const AuthState.authenticated('user-123')],
  );

  blocTest<AuthBloc, AuthState>(
    'emits a friendly unauthenticated error when sign-in throws wrong-password',
    build: () => AuthBloc(authRepository: authRepository),
    setUp: () {
      when(() => authRepository.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));
    },
    act: (bloc) => bloc.add(
      const AuthSignInRequested(email: 'a@b.com', password: 'bad'),
    ),
    expect: () => [
      const AuthState.unauthenticated('Incorrect email or password.'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits a friendly unauthenticated error when sign-up throws email-already-in-use',
    build: () => AuthBloc(authRepository: authRepository),
    setUp: () {
      when(() => authRepository.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
    },
    act: (bloc) => bloc.add(
      const AuthSignUpRequested(email: 'a@b.com', password: 'pw123456'),
    ),
    expect: () => [
      const AuthState.unauthenticated(
        'An account already exists with that email.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'calls signOut on the repository when sign-out is requested',
    build: () => AuthBloc(authRepository: authRepository),
    setUp: () {
      when(() => authRepository.signOut()).thenAnswer((_) async {});
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    verify: (_) {
      verify(() => authRepository.signOut()).called(1);
    },
  );
}
