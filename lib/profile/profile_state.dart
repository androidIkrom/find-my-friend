import 'dart:io';

import 'package:equatable/equatable.dart';

enum ProfileStatus { initial, submitting, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.name = '',
    this.avatarFile,
    this.existingAvatarUrl,
    this.status = ProfileStatus.initial,
    this.errorMessage,
  });

  final String name;
  final File? avatarFile;
  final String? existingAvatarUrl;
  final ProfileStatus status;
  final String? errorMessage;

  bool get hasAvatar => avatarFile != null || existingAvatarUrl != null;

  ProfileState copyWith({
    String? name,
    File? avatarFile,
    String? existingAvatarUrl,
    ProfileStatus? status,
    String? errorMessage,
  }) {
    return ProfileState(
      name: name ?? this.name,
      avatarFile: avatarFile ?? this.avatarFile,
      existingAvatarUrl: existingAvatarUrl ?? this.existingAvatarUrl,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [name, avatarFile, existingAvatarUrl, status, errorMessage];
}
