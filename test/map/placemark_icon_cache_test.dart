import 'dart:typed_data';

import 'package:find_my_friend/map/avatar_fetcher.dart';
import 'package:find_my_friend/map/circular_avatar_renderer.dart';
import 'package:find_my_friend/map/placemark_icon_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAvatarFetcher extends Mock implements AvatarFetcher {}

class MockCircularAvatarRenderer extends Mock
    implements CircularAvatarRenderer {}

void main() {
  late MockAvatarFetcher fetcher;
  late MockCircularAvatarRenderer renderer;
  late PlacemarkIconCache cache;

  setUp(() {
    fetcher = MockAvatarFetcher();
    renderer = MockCircularAvatarRenderer();
    cache = PlacemarkIconCache(fetcher: fetcher, renderer: renderer);
  });

  test('fetches and renders an icon the first time it is requested', () async {
    final sourceBytes = Uint8List.fromList([1, 2, 3]);
    final pngBytes = Uint8List.fromList([4, 5, 6]);
    when(() => fetcher.fetch('https://example.com/a.jpg'))
        .thenAnswer((_) async => sourceBytes);
    when(() => renderer.render(sourceBytes)).thenAnswer((_) async => pngBytes);

    await cache.iconFor('https://example.com/a.jpg');

    verify(() => fetcher.fetch('https://example.com/a.jpg')).called(1);
    verify(() => renderer.render(sourceBytes)).called(1);
  });

  test('reuses the cached icon on subsequent calls for the same URL', () async {
    final sourceBytes = Uint8List.fromList([1, 2, 3]);
    final pngBytes = Uint8List.fromList([4, 5, 6]);
    when(() => fetcher.fetch('https://example.com/a.jpg'))
        .thenAnswer((_) async => sourceBytes);
    when(() => renderer.render(sourceBytes)).thenAnswer((_) async => pngBytes);

    await cache.iconFor('https://example.com/a.jpg');
    await cache.iconFor('https://example.com/a.jpg');

    verify(() => fetcher.fetch('https://example.com/a.jpg')).called(1);
  });

  test('shares one in-flight request for concurrent calls to the same URL', () async {
    final sourceBytes = Uint8List.fromList([1, 2, 3]);
    final pngBytes = Uint8List.fromList([4, 5, 6]);
    when(() => fetcher.fetch('https://example.com/a.jpg')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return sourceBytes;
    });
    when(() => renderer.render(sourceBytes)).thenAnswer((_) async => pngBytes);

    final first = cache.iconFor('https://example.com/a.jpg');
    final second = cache.iconFor('https://example.com/a.jpg');
    await Future.wait([first, second]);

    verify(() => fetcher.fetch('https://example.com/a.jpg')).called(1);
  });
}
