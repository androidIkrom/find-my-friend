import 'package:equatable/equatable.dart';

import 'map_user.dart';

class UsersMapState extends Equatable {
  const UsersMapState({this.users = const [], this.hasError = false});

  final List<MapUser> users;
  final bool hasError;

  @override
  List<Object?> get props => [users, hasError];
}
