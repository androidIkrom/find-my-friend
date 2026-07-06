import 'dart:convert';
import 'dart:typed_data';

import 'package:find_my_friend/map/placemark_icon_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlacemarkIconCache cache;

  setUp(() {
    cache = PlacemarkIconCache();
  });

  test('decodes a base64 avatar into a BitmapDescriptor', () {
    final avatarBase64 = base64Encode(Uint8List.fromList([1, 2, 3]));

    final descriptor = cache.iconFor(avatarBase64);

    expect(descriptor, isNotNull);
  });

  test('reuses the cached descriptor for the same base64 string', () {
    final avatarBase64 = base64Encode(Uint8List.fromList([4, 5, 6]));

    final first = cache.iconFor(avatarBase64);
    final second = cache.iconFor(avatarBase64);

    expect(identical(first, second), isTrue);
  });

  test('returns different descriptors for different avatars', () {
    final avatarA = base64Encode(Uint8List.fromList([7, 8, 9]));
    final avatarB = base64Encode(Uint8List.fromList([10, 11, 12]));

    final first = cache.iconFor(avatarA);
    final second = cache.iconFor(avatarB);

    expect(identical(first, second), isFalse);
  });
}
