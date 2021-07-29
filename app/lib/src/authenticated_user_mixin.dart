import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'shared.dart';

mixin AuthenticatedUserMixin on ChangeNotifier {
  final _client = BrowserClient();

  Future<String> requestBearerToken();

  Future<Response> get(Uri url, {Map<String, String>? headers}) async =>
      _client.get(
        url,
        headers: await _headers(headers),
      );

  Future<Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async =>
      _client.put(
        url,
        headers: await _headers(headers),
        body: body,
      );

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<Map<String, String>> _headers(Map<String, String>? headers) async {
    assert(headers == null || !headers.containsKey('Authorization'));
    final firebaseIdToken = await requestBearerToken();

    return {
      ...authHeaders(firebaseIdToken),
      ...?headers,
    };
  }
}
