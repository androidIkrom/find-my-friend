import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'circular_avatar_renderer.dart';

class ProfileRepository {
  ProfileRepository({
    FirebaseFirestore? firestore,
    CircularAvatarRenderer? avatarRenderer,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _avatarRenderer = avatarRenderer ?? const CircularAvatarRenderer();

  final FirebaseFirestore _firestore;
  final CircularAvatarRenderer _avatarRenderer;

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

  Future<String> encodeAvatar(File file) async {
    final sourceBytes = await file.readAsBytes();
    final pngBytes = await _avatarRenderer.render(sourceBytes);
    return base64Encode(pngBytes);
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String avatarBase64,
    GeoPoint? location,
    required bool isNewProfile,
  }) {
    final doc = _firestore.collection('users').doc(uid);
    final data = <String, dynamic>{
      'name': name,
      'avatarBase64': avatarBase64,
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
