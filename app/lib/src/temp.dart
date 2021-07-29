import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:knarly_common/knarly_common.dart';

import 'network_exception.dart';
import 'shared.dart';

Future<Election> downloadFirstElection(User user) async {
  final firebaseIdToken = await user.getIdToken();

  final uri = Uri.parse('api/elections/');
  final response = await get(uri, headers: authHeaders(firebaseIdToken));
  if (response.statusCode != 200) {
    throw NetworkException(
      'Bad response from service! ${response.statusCode}. '
      '${response.body}',
      statusCode: response.statusCode,
      uri: uri,
    );
  }
  final json = jsonDecode(response.body) as List;
  if (json.isEmpty) {
    throw StateError('No values returned!');
  }

  return Election.fromJson(json.first as Map<String, dynamic>);
}
