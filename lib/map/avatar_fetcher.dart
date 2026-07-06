import 'dart:typed_data';

import 'package:http/http.dart' as http;

class AvatarFetcher {
  AvatarFetcher({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Uint8List> fetch(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw StateError('Failed to load avatar: HTTP ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
