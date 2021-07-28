import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

mixin AuthenticatedUserMixin on ChangeNotifier {
  final _client = BrowserClient();

  User get user;

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
    final firebaseIdToken = await user.getIdToken();

    return {
      'Authorization': 'Bearer $firebaseIdToken',
      ...?headers,
    };
  }
}
