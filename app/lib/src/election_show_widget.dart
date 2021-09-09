import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:knarly_common/knarly_common.dart';

import 'network_exception.dart';
import 'shared.dart';
import 'vote_widget.dart';

class ElectionShowWidget extends StatelessWidget {
  final User _user;
  final String _electionId;
  const ElectionShowWidget(this._user, this._electionId, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => FutureBuilder<Election>(
        future: _downloadFirstElection(_user, _electionId),
        builder: (buildContext, snapshot) {
          if (snapshot.hasError) {
            // TODO: Probably could do something a bit better here...
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.hasData) {
            return VoteWidget(_user, snapshot.requireData);
          }

          return const Center(child: Text('Downloading election...'));
        },
      );
}

Future<Election> _downloadFirstElection(User user, String electionId) async {
  final firebaseIdToken = await user.getIdToken();

  final uri = Uri.parse('api/elections/$electionId/');
  final response = await get(uri, headers: authHeaders(firebaseIdToken));
  if (response.statusCode != 200) {
    throw NetworkException(
      'Bad response from service! ${response.statusCode}. '
      '${response.body}',
      statusCode: response.statusCode,
      uri: uri,
    );
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;

  return Election.fromJson(json);
}
