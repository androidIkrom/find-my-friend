import 'dart:typed_data';

import 'package:yandex_mapkit/yandex_mapkit.dart';

import 'avatar_fetcher.dart';
import 'circular_avatar_renderer.dart';

class PlacemarkIconCache {
  PlacemarkIconCache({AvatarFetcher? fetcher, CircularAvatarRenderer? renderer})
      : _fetcher = fetcher ?? AvatarFetcher(),
        _renderer = renderer ?? const CircularAvatarRenderer();

  final AvatarFetcher _fetcher;
  final CircularAvatarRenderer _renderer;
  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, Future<BitmapDescriptor>> _pending = {};

  Future<BitmapDescriptor> iconFor(String avatarUrl) {
    final cached = _cache[avatarUrl];
    if (cached != null) return Future.value(cached);

    final inFlight = _pending[avatarUrl];
    if (inFlight != null) return inFlight;

    final future = _load(avatarUrl);
    _pending[avatarUrl] = future;
    return future;
  }

  Future<BitmapDescriptor> _load(String avatarUrl) async {
    try {
      final sourceBytes = await _fetcher.fetch(avatarUrl);
      final Uint8List pngBytes = await _renderer.render(sourceBytes);
      final descriptor = BitmapDescriptor.fromBytes(pngBytes);
      _cache[avatarUrl] = descriptor;
      return descriptor;
    } finally {
      _pending.remove(avatarUrl);
    }
  }
}
