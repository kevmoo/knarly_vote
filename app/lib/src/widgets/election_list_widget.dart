import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import '../auth_model.dart';
import 'network_async_widget.dart';

class ElectionListWidget extends StatelessWidget {
  const ElectionListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<FirebaseAuthModel>(
        builder: (ctx, value, _) => NetworkAsyncWidget<List<ElectionPreview>>(
          valueFactory: () => _listElections(value),
          waitingText: 'Downloading elections...',
          builder: (ctx, data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < data.length; index++)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () =>
                        Routemaster.of(context).push(data[index].id),
                    child: Text(data[index].name),
                  ),
                ),
            ],
          ),
        ),
      );
}

Future<List<ElectionPreview>> _listElections(FirebaseAuthModel usr) async {
  final json = await usr.sendJson('GET', 'api/elections/') as List;
  if (json.isEmpty) {
    throw StateError('No values returned!');
  }

  return json
      .map((e) => ElectionPreview.fromJson(e as Map<String, dynamic>))
      .toList();
}
