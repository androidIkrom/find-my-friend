import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_friend/map/map_user.dart';
import 'package:find_my_friend/map/users_map_cubit.dart';
import 'package:find_my_friend/map/users_map_repository.dart';
import 'package:find_my_friend/map/users_map_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockUsersMapRepository extends Mock implements UsersMapRepository {}

class FakePosition extends Fake implements Position {
  FakePosition(this.latitude, this.longitude);

  @override
  final double latitude;

  @override
  final double longitude;
}

void main() {
  late MockUsersMapRepository repository;

  setUpAll(() {
    registerFallbackValue(const GeoPoint(0, 0));
  });

  const aliceHere = MapUser(
    uid: 'alice',
    name: 'Alice',
    avatarBase64: 'YWxpY2UtYXZhdGFy',
    latitude: 10,
    longitude: 20,
  );
  const bobHere = MapUser(
    uid: 'bob',
    name: 'Bob',
    avatarBase64: 'Ym9iLWF2YXRhcg==',
    latitude: 30,
    longitude: 40,
  );

  setUp(() {
    repository = MockUsersMapRepository();
  });

  blocTest<UsersMapCubit, UsersMapState>(
    'emits the user list whenever Firestore publishes an update',
    build: () {
      when(() => repository.positionStream())
          .thenAnswer((_) => const Stream<Position>.empty());
      when(() => repository.watchUsers()).thenAnswer(
        (_) => Stream<List<MapUser>>.fromIterable([
          [aliceHere],
          [aliceHere, bobHere],
        ]),
      );
      return UsersMapCubit(repository: repository, uid: 'alice');
    },
    act: (cubit) => cubit.start(),
    expect: () => [
      const UsersMapState(users: [aliceHere]),
      const UsersMapState(users: [aliceHere, bobHere]),
    ],
  );

  blocTest<UsersMapCubit, UsersMapState>(
    'writes each new device position to the repository as the signed-in user',
    build: () {
      when(() => repository.positionStream()).thenAnswer(
        (_) => Stream<Position>.fromIterable([FakePosition(1, 2)]),
      );
      when(() => repository.watchUsers())
          .thenAnswer((_) => const Stream<List<MapUser>>.empty());
      when(() => repository.updateLocation(any(), any()))
          .thenAnswer((_) async {});
      return UsersMapCubit(repository: repository, uid: 'alice');
    },
    act: (cubit) async {
      cubit.start();
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) {
      verify(() => repository.updateLocation('alice', const GeoPoint(1, 2)))
          .called(1);
    },
  );

  blocTest<UsersMapCubit, UsersMapState>(
    'keeps the last known users and sets hasError when the users stream errors',
    build: () {
      when(() => repository.positionStream())
          .thenAnswer((_) => const Stream<Position>.empty());
      when(() => repository.watchUsers()).thenAnswer(
        (_) => Stream<List<MapUser>>.multi((controller) {
          controller.add([aliceHere]);
          controller.addError(StateError('permission-denied'));
        }),
      );
      return UsersMapCubit(repository: repository, uid: 'alice');
    },
    act: (cubit) => cubit.start(),
    expect: () => [
      const UsersMapState(users: [aliceHere]),
      const UsersMapState(users: [aliceHere], hasError: true),
    ],
  );
}
