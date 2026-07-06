import 'dart:convert';

import 'package:yandex_mapkit/yandex_mapkit.dart';

/// Decodes the already circular-cropped avatar PNG stored as base64 in each
/// user's Firestore document into a [BitmapDescriptor], caching the result
/// per base64 string so repeated snapshots don't re-decode unchanged avatars.
class PlacemarkIconCache {
  final Map<String, BitmapDescriptor> _cache = {};

  BitmapDescriptor iconFor(String avatarBase64) {
    final cached = _cache[avatarBase64];
    if (cached != null) return cached;

    final bytes = base64Decode(avatarBase64);
    final descriptor = BitmapDescriptor.fromBytes(bytes);
    _cache[avatarBase64] = descriptor;
    return descriptor;
  }
}
