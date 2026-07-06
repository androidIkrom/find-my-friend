import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'map_user.dart';

class UsersMapRepository {
  UsersMapRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<Position> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<void> updateLocation(String uid, GeoPoint location) {
    return _firestore.collection('users').doc(uid).set(
      {
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<MapUser>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['name'] != null &&
                data['avatarBase64'] != null &&
                data['location'] != null;
          })
          .map((doc) {
            final data = doc.data();
            final location = data['location'] as GeoPoint;
            return MapUser(
              uid: doc.id,
              name: data['name'] as String,
              avatarBase64: data['avatarBase64'] as String,
              latitude: location.latitude,
              longitude: location.longitude,
            );
          })
          .toList();
    });
  }
}
