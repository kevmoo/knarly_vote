import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';

import 'network_exception.dart';

const siteTitle = 'Knarly Vote';

Map<String, String> authHeaders(String bearerToken) =>
    {'Authorization': 'Bearer $bearerToken'};

extension ObjectExt on Object {
  void doLog(Object? object) => print('$this : $object');
}

Future<Object?> getJson(User user, String url) async {
  final firebaseIdToken = await user.getIdToken();

  final uri = Uri.parse(url);
  final response = await get(uri, headers: authHeaders(firebaseIdToken));
  if (response.statusCode != 200) {
    throw NetworkException(
      'Bad response from service! ${response.statusCode}. '
      '${response.body}',
      statusCode: response.statusCode,
      uri: uri,
    );
  }

  return jsonDecode(response.body);
}
