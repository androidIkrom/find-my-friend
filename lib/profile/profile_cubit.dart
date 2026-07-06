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
    String? initialAvatarBase64,
  })  : _repository = repository,
        _uid = uid,
        _isNewProfile = initialAvatarBase64 == null,
        super(
          ProfileState(
            name: initialName,
            existingAvatarBase64: initialAvatarBase64,
          ),
        );

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

      final avatarBase64 = state.avatarFile != null
          ? await _repository.encodeAvatar(state.avatarFile!)
          : state.existingAvatarBase64!;

      await _repository.saveProfile(
        uid: _uid,
        name: state.name.trim(),
        avatarBase64: avatarBase64,
        location: location,
        isNewProfile: _isNewProfile,
      );

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          existingAvatarBase64: avatarBase64,
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
