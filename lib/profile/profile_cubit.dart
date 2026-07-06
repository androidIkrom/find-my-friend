import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository repository,
    required String uid,
    String initialName = '',
    String? initialAvatarUrl,
  })  : _repository = repository,
        _uid = uid,
        _isNewProfile = initialAvatarUrl == null,
        super(ProfileState(name: initialName, existingAvatarUrl: initialAvatarUrl));

  final ProfileRepository _repository;
  final String _uid;
  final bool _isNewProfile;

  void nameChanged(String name) {
    emit(state.copyWith(name: name, errorMessage: null));
  }

  void avatarSelected(File file) {
    emit(state.copyWith(avatarFile: file, errorMessage: null));
  }

  Future<void> submit() async {
    if (state.name.trim().isEmpty || !state.hasAvatar) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Enter a name and choose an avatar.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: ProfileStatus.submitting, errorMessage: null));

    try {
      GeoPoint? location;

      if (_isNewProfile) {
        final granted = await _repository.ensureLocationPermission();
        if (!granted) {
          emit(
            state.copyWith(
              status: ProfileStatus.failure,
              errorMessage: 'Location permission is required to continue.',
            ),
          );
          return;
        }

        final position = await _repository.getCurrentPosition();
        location = GeoPoint(position.latitude, position.longitude);
      }

      final avatarUrl = state.avatarFile != null
          ? await _repository.uploadAvatar(_uid, state.avatarFile!)
          : state.existingAvatarUrl!;

      await _repository.saveProfile(
        uid: _uid,
        name: state.name.trim(),
        avatarUrl: avatarUrl,
        location: location,
        isNewProfile: _isNewProfile,
      );

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          existingAvatarUrl: avatarUrl,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          errorMessage: 'Something went wrong. Please try again.',
        ),
      );
    }
  }
}
