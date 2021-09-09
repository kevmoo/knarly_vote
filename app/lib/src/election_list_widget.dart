import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:routemaster/routemaster.dart';

import 'shared.dart';

class ElectionListWidget extends StatelessWidget {
  final User _user;
  const ElectionListWidget(this._user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Election>>(
        future: _listElections(_user),
        builder: (context, snapshot) {
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
            final _elections = snapshot.requireData;
            return ListView.builder(
              itemCount: _elections.length,
              itemBuilder: (ctx, index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () =>
                      Routemaster.of(context).push(_elections[index].id),
                  child: Text(_elections[index].name),
                ),
              ),
            );
          }

          return const Center(child: Text('Downloading elections...'));
        },
      );
}

Future<List<Election>> _listElections(User user) async {
  final json = await getJson(user, 'api/elections/') as List;
  if (json.isEmpty) {
    throw StateError('No values returned!');
  }

  return json.map((e) => Election.fromJson(e as Map<String, dynamic>)).toList();
}
