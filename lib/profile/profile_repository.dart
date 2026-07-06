import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<bool> ensureLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String avatarUrl,
    GeoPoint? location,
    required bool isNewProfile,
  }) {
    final doc = _firestore.collection('users').doc(uid);
    final data = <String, dynamic>{
      'name': name,
      'avatarUrl': avatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (location != null) {
      data['location'] = location;
    }
    if (isNewProfile) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    return doc.set(data, SetOptions(merge: true));
  }
}
