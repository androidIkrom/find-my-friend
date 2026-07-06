import 'dart:io';

import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, submitting, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.name = '',
    this.avatarFile,
    this.existingAvatarBase64,
    this.status = ProfileStatus.initial,
    this.errorMessage,
  });

  final String name;
  final File? avatarFile;
  final String? existingAvatarBase64;
  final ProfileStatus status;
  final String? errorMessage;

  bool get hasAvatar => avatarFile != null || existingAvatarBase64 != null;

  ProfileState copyWith({
    String? name,
    File? avatarFile,
    String? existingAvatarBase64,
    ProfileStatus? status,
    String? errorMessage,
  }) {
    return ProfileState(
      name: name ?? this.name,
      avatarFile: avatarFile ?? this.avatarFile,
      existingAvatarBase64: existingAvatarBase64 ?? this.existingAvatarBase64,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [name, avatarFile, existingAvatarBase64, status, errorMessage];
}
