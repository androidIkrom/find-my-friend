import 'package:equatable/equatable.dart';

class MapUser extends Equatable {
  const MapUser({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.latitude,
    required this.longitude,
  });

  final String uid;
  final String name;
  final String avatarUrl;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [uid, name, avatarUrl, latitude, longitude];
}
