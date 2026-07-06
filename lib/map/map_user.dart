import 'package:equatable/equatable.dart';

class MapUser extends Equatable {
  const MapUser({
    required this.uid,
    required this.name,
    required this.avatarBase64,
    required this.latitude,
    required this.longitude,
  });

  final String uid;
  final String name;
  final String avatarBase64;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [uid, name, avatarBase64, latitude, longitude];
}
