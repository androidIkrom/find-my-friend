import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'map_user.dart';
import 'users_map_repository.dart';
import 'users_map_state.dart';

class UsersMapCubit extends Cubit<UsersMapState> {
  UsersMapCubit({required UsersMapRepository repository, required String uid})
      : _repository = repository,
        _uid = uid,
        super(const UsersMapState());

  final UsersMapRepository _repository;
  final String _uid;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<List<MapUser>>? _usersSubscription;

  void start() {
    _positionSubscription = _repository.positionStream().listen((position) {
      _repository.updateLocation(
        _uid,
        GeoPoint(position.latitude, position.longitude),
      );
    });

    _usersSubscription = _repository.watchUsers().listen(
      (users) => emit(UsersMapState(users: users)),
      onError: (_) => emit(UsersMapState(users: state.users, hasError: true)),
    );
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _usersSubscription?.cancel();
    return super.close();
  }
}
