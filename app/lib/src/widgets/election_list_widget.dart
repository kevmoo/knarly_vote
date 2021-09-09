import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:routemaster/routemaster.dart';

import '../shared.dart';
import 'network_async_widget.dart';

class ElectionListWidget extends StatelessWidget {
  final User _user;
  const ElectionListWidget(this._user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => NetworkAsyncWidget<List<Election>>(
        future: _listElections(_user),
        waitingText: 'Downloading elections...',
        builder: (ctx, data) => ListView.builder(
          itemCount: data.length,
          itemBuilder: (ctx, index) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => Routemaster.of(context).push(data[index].id),
              child: Text(data[index].name),
            ),
          ),
        ),
      );
}

Future<List<Election>> _listElections(User user) async {
  final json = await getJson(user, 'api/elections/') as List;
  if (json.isEmpty) {
    throw StateError('No values returned!');
  }

  return json.map((e) => Election.fromJson(e as Map<String, dynamic>)).toList();
}
