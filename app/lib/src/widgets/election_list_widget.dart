import 'package:flutter/material.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:provider/provider.dart';

import '../auth_model.dart';
import '../routing.dart';
import 'network_async_widget.dart';

class ElectionListWidget extends StatelessWidget {
  const ElectionListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<FirebaseAuthModel>(
        builder: (ctx, value, _) => NetworkAsyncWidget<List<ElectionPreview>>(
          valueFactory: () => _listElections(value),
          waitingText: 'Downloading elections...',
          builder: (ctx, data) => Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            textBaseline: TextBaseline.alphabetic,
            columnWidths: {
              0: const FractionColumnWidth(.7),
              1: const FlexColumnWidth(),
              2: const FlexColumnWidth(),
            },
            children: List.generate(
              data.length + 1,
              (index) {
                if (index == 0) {
                  return const TableRow(
                    children: [
                      Center(child: Text('Election')),
                      Center(child: Text('Voted')),
                      Center(child: Text('Total votes')),
                    ],
                  );
                }
                final item = data[index - 1];
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () => context.pushViewElection(item.id),
                        child: Text(item.name),
                      ),
                    ),
                    Center(
                      child: Text(item.userVoted ? '✔️' : ''),
                    ),
                    Center(
                      child: Text(item.ballotCount.toString()),
                    ),
                  ],
                );
              },
            ),
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
