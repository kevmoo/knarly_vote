import 'package:flutter/material.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:provider/provider.dart';

import '../auth_model.dart';
import 'network_async_widget.dart';
import 'vote_widget.dart';

class ElectionShowWidget extends StatelessWidget {
  final String _electionId;
  const ElectionShowWidget(this._electionId, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<FirebaseAuthModel>(
        builder: (ctx, value, _) => NetworkAsyncWidget<Election>(
          valueFactory: () => _downloadFirstElection(value),
          waitingText: 'Downloading election...',
          builder: (ctx, data) => VoteWidget(user: value, data: data),
        ),
      );

  Future<Election> _downloadFirstElection(FirebaseAuthModel _user) async {
    final json = await _user.sendJson('GET', 'api/elections/$_electionId/')
        as Map<String, dynamic>;

    return Election.fromJson(json);
  }
}
