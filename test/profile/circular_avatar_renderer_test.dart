import 'dart:convert';

import 'package:find_my_friend/profile/circular_avatar_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

const _onePixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render produces valid PNG bytes', () async {
    final sourceBytes = base64Decode(_onePixelPngBase64);
    const renderer = CircularAvatarRenderer();

    final result = await renderer.render(sourceBytes, size: 32);

    expect(result.length, greaterThan(8));
    expect(result.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });
}
