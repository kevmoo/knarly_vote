import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:knarly_common/knarly_common.dart';

import '../shared.dart';
import 'network_async_widget.dart';
import 'vote_widget.dart';

class ElectionShowWidget extends StatelessWidget {
  final User _user;
  final String _electionId;
  const ElectionShowWidget(this._user, this._electionId, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) => NetworkAsyncWidget<Election>(
        valueFactory: _downloadFirstElection,
        waitingText: 'Downloading election...',
        builder: (ctx, data) => VoteWidget(_user, data),
      );

  Future<Election> _downloadFirstElection() async {
    final json = await getJson(_user, 'api/elections/$_electionId/')
        as Map<String, dynamic>;

    return Election.fromJson(json);
  }
}
