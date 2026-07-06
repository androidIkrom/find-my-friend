import 'package:bloc_test/bloc_test.dart';
import 'package:find_my_friend/profile/profile_cubit.dart';
import 'package:find_my_friend/profile/profile_setup_screen.dart';
import 'package:find_my_friend/profile/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileCubit extends MockCubit<ProfileState> implements ProfileCubit {}

void main() {
  late MockProfileCubit cubit;

  setUp(() {
    cubit = MockProfileCubit();
    when(() => cubit.state).thenReturn(const ProfileState());
    whenListen(
      cubit,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState(),
    );
    // Additive fix: MockCubit's submit() is a Future<void>-returning method
    // and mocktail returns null for unstubbed calls, which throws a
    // _TypeError when the widget awaits it. Stub it so the tap handler's
    // `context.read<ProfileCubit>().submit()` call doesn't blow up.
    when(() => cubit.submit()).thenAnswer((_) async {});
  });

  Widget buildSubject({VoidCallback? onComplete}) {
    return MaterialApp(
      home: BlocProvider<ProfileCubit>.value(
        value: cubit,
        child: ProfileSetupScreen(onComplete: onComplete ?? () {}),
      ),
    );
  }

  testWidgets('typing a name calls nameChanged on the cubit', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.enterText(find.byKey(const Key('nameField')), 'Ada');
    verify(() => cubit.nameChanged('Ada')).called(1);
  });

  testWidgets('tapping continue calls submit on the cubit', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.tap(find.byKey(const Key('continueButton')));
    verify(() => cubit.submit()).called(1);
  });

  testWidgets('shows a spinner and disables the button while submitting', (tester) async {
    when(() => cubit.state).thenReturn(
      const ProfileState(name: 'Ada', status: ProfileStatus.submitting),
    );
    whenListen(
      cubit,
      const Stream<ProfileState>.empty(),
      initialState: const ProfileState(name: 'Ada', status: ProfileStatus.submitting),
    );
    await tester.pumpWidget(buildSubject());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('continueButton')),
    );
    expect(button.onPressed, isNull);
  });
}
