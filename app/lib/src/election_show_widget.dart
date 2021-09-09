import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:knarly_common/knarly_common.dart';

import 'network_async_widget.dart';
import 'shared.dart';
import 'vote_widget.dart';

class ElectionShowWidget extends StatelessWidget {
  final User _user;
  final String _electionId;
  const ElectionShowWidget(this._user, this._electionId, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => NetworkAsyncWidget<Election>(
        future: _downloadFirstElection(_user, _electionId),
        waitingText: 'Downloading election...',
        builder: (ctx, data) => VoteWidget(_user, data),
      );
}

Future<Election> _downloadFirstElection(User user, String electionId) async {
  final json =
      await getJson(user, 'api/elections/$electionId/') as Map<String, dynamic>;

  return Election.fromJson(json);
}
