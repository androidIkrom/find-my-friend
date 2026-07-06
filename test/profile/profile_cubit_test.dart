import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_my_friend/profile/profile_cubit.dart';
import 'package:find_my_friend/profile/profile_repository.dart';
import 'package:find_my_friend/profile/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakePosition extends Fake implements Position {
  FakePosition(this.latitude, this.longitude);

  @override
  final double latitude;

  @override
  final double longitude;
}

void main() {
  late MockProfileRepository repository;
  final avatarFile = File('avatar.jpg');

  setUpAll(() {
    registerFallbackValue(const GeoPoint(0, 0));
    registerFallbackValue(File('fallback.jpg'));
  });

  setUp(() {
    repository = MockProfileRepository();
  });

  group('ProfileCubit.submit validation', () {
    blocTest<ProfileCubit, ProfileState>(
      'fails when name is empty',
      build: () => ProfileCubit(repository: repository, uid: 'uid-1'),
      seed: () => ProfileState(avatarFile: avatarFile),
      act: (cubit) => cubit.submit(),
      expect: () => [
        ProfileState(
          avatarFile: avatarFile,
          status: ProfileStatus.failure,
          errorMessage: 'Enter a name and choose an avatar.',
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'fails when no avatar has been chosen',
      build: () => ProfileCubit(repository: repository, uid: 'uid-1'),
      seed: () => const ProfileState(name: 'Ada'),
      act: (cubit) => cubit.submit(),
      expect: () => [
        const ProfileState(
          name: 'Ada',
          status: ProfileStatus.failure,
          errorMessage: 'Enter a name and choose an avatar.',
        ),
      ],
    );
  });

  group('ProfileCubit.submit with a new profile', () {
    blocTest<ProfileCubit, ProfileState>(
      'fails with a message when location permission is denied',
      build: () => ProfileCubit(repository: repository, uid: 'uid-1'),
      seed: () => ProfileState(name: 'Ada', avatarFile: avatarFile),
      setUp: () {
        when(() => repository.ensureLocationPermission())
            .thenAnswer((_) async => false);
      },
      act: (cubit) => cubit.submit(),
      expect: () => [
        ProfileState(
          name: 'Ada',
          avatarFile: avatarFile,
          status: ProfileStatus.submitting,
        ),
        ProfileState(
          name: 'Ada',
          avatarFile: avatarFile,
          status: ProfileStatus.failure,
          errorMessage: 'Location permission is required to continue.',
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'uploads the avatar, saves the profile, and emits success',
      build: () => ProfileCubit(repository: repository, uid: 'uid-1'),
      seed: () => ProfileState(name: 'Ada', avatarFile: avatarFile),
      setUp: () {
        when(() => repository.ensureLocationPermission())
            .thenAnswer((_) async => true);
        when(() => repository.getCurrentPosition())
            .thenAnswer((_) async => FakePosition(1.0, 2.0));
        when(() => repository.uploadAvatar('uid-1', avatarFile))
            .thenAnswer((_) async => 'https://example.com/avatar.jpg');
        when(() => repository.saveProfile(
              uid: any(named: 'uid'),
              name: any(named: 'name'),
              avatarUrl: any(named: 'avatarUrl'),
              location: any(named: 'location'),
              isNewProfile: any(named: 'isNewProfile'),
            )).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.submit(),
      expect: () => [
        ProfileState(
          name: 'Ada',
          avatarFile: avatarFile,
          status: ProfileStatus.submitting,
        ),
        ProfileState(
          name: 'Ada',
          avatarFile: avatarFile,
          status: ProfileStatus.success,
          existingAvatarUrl: 'https://example.com/avatar.jpg',
        ),
      ],
      verify: (_) {
        verify(() => repository.saveProfile(
              uid: 'uid-1',
              name: 'Ada',
              avatarUrl: 'https://example.com/avatar.jpg',
              location: const GeoPoint(1.0, 2.0),
              isNewProfile: true,
            )).called(1);
      },
    );
  });

  group('ProfileCubit.submit editing an existing profile', () {
    blocTest<ProfileCubit, ProfileState>(
      'reuses the existing avatar URL when no new avatar is picked',
      build: () => ProfileCubit(
        repository: repository,
        uid: 'uid-1',
        initialName: 'Ada',
        initialAvatarUrl: 'https://example.com/old.jpg',
      ),
      setUp: () {
        when(() => repository.saveProfile(
              uid: any(named: 'uid'),
              name: any(named: 'name'),
              avatarUrl: any(named: 'avatarUrl'),
              location: any(named: 'location'),
              isNewProfile: any(named: 'isNewProfile'),
            )).thenAnswer((_) async {});
      },
      act: (cubit) => cubit.submit(),
      expect: () => [
        const ProfileState(
          name: 'Ada',
          existingAvatarUrl: 'https://example.com/old.jpg',
          status: ProfileStatus.submitting,
        ),
        const ProfileState(
          name: 'Ada',
          existingAvatarUrl: 'https://example.com/old.jpg',
          status: ProfileStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => repository.saveProfile(
              uid: 'uid-1',
              name: 'Ada',
              avatarUrl: 'https://example.com/old.jpg',
              location: null,
              isNewProfile: false,
            )).called(1);
        verifyNever(() => repository.uploadAvatar(any(), any()));
        verifyNever(() => repository.ensureLocationPermission());
        verifyNever(() => repository.getCurrentPosition());
      },
    );
  });
}
