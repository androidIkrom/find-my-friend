import 'package:bloc_test/bloc_test.dart';
import 'package:find_my_friend/auth/auth_bloc.dart';
import 'package:find_my_friend/auth/auth_event.dart';
import 'package:find_my_friend/auth/auth_screen.dart';
import 'package:find_my_friend/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    whenListen(
      authBloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unknown(),
    );
  });

  Widget buildSubject() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const AuthScreen(),
      ),
    );
  }

  testWidgets('shows a validation error when email is empty', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pump();
    expect(find.text('Enter your email.'), findsOneWidget);
  });

  testWidgets('dispatches AuthSignInRequested with valid input', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pump();
    verify(
      () => authBloc.add(
        const AuthSignInRequested(email: 'a@b.com', password: 'password123'),
      ),
    ).called(1);
  });

  testWidgets('toggling mode dispatches AuthSignUpRequested instead', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byKey(const Key('toggleModeButton')));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('emailField')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('passwordField')), 'password123');
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pump();
    verify(
      () => authBloc.add(
        const AuthSignUpRequested(email: 'a@b.com', password: 'password123'),
      ),
    ).called(1);
  });
}
