import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'network_exception.dart';
import 'shared.dart';

class FirebaseAuthModel extends ChangeNotifier {
  final _client = BrowserClient();

  final _initializeCompleter = Completer<bool>.sync();

  late final StreamSubscription<User?> _subscription;

  Future<bool> get initializationComplete => _initializeCompleter.future;

  User? get user => FirebaseAuth.instance.currentUser;

  FirebaseAuthModel() {
    _subscription = FirebaseAuth.instance.userChanges().listen((_) {
      if (!_initializeCompleter.isCompleted) {
        _initializeCompleter.complete(true);
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _client.close();
    _subscription.cancel();
    super.dispose();
  }

  Future<Response> send(
    String method,
    Uri url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final authHeaders = await _headers(headers);
    final request = Request(
      method,
      url,
    )..headers.addAll(authHeaders);

    if (body != null) {
      request.body = body;
    }

    final streamResponse = await _client.send(request);
    return Response.fromStream(streamResponse);
  }

  Future<Response> get(Uri url, {Map<String, String>? headers}) async =>
      await send('GET', url, headers: headers);

  Future<Object?> sendJson(
    String method,
    Object url, {
    Object? jsonBody,
  }) async {
    final uri = url is String ? Uri.parse(url) : url as Uri;

    final headers = {
      if (jsonBody != null) 'Content-Type': 'application/json',
    };
    final response = await send(
      method,
      uri,
      headers: headers,
      body: jsonBody == null ? null : jsonEncode(jsonBody),
    );
    if (response.statusCode != 200) {
      throw NetworkException(
        'Bad response from service. ${response.body}',
        statusCode: response.statusCode,
        uri: uri,
        cloudTraceContext: response.headers['x-cloud-trace-context'],
      );
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, String>> _headers(Map<String, String>? headers) async {
    assert(headers == null || !headers.containsKey('Authorization'));
    final firebaseIdToken = await user!.getIdToken();

    return {
      ...authHeaders(firebaseIdToken),
      ...?headers,
    };
  }
}
