import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:vote_widgets/vote_widgets.dart';

import '../election_result_model.dart';
import '../provider_consumer_combo.dart';
import '../user_voting_model.dart';
import '../vote_model.dart';

class VoteWidget extends StatelessWidget {
  final User _user;
  final Election _data;

  VoteWidget(this._user, this._data);

  @override
  Widget build(BuildContext context) => createProviderConsumer<UserVotingModel>(
        create: (_) => UserVotingModel(_user, _data),
        builder: (context, model, __) {
          final electionModel = model.electionResultModel;
          final voteModel = model.voteModel;

          return Column(
            children: [
              Text(
                'State: ${model.state.name}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              if (model.state == UserVotingModelState.error)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Check out the dev console. Reload?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  model.electionName,
                  textScaleFactor: 2,
                ),
              ),
              valueProviderConsumer<ElectionResultModel>(
                value: electionModel,
                builder: (_, model, __) {
                  final result = model.value;
                  if (result == null) {
                    return const Text(
                      'Waiting for result to be calculated...',
                    );
                  }
                  final ballotCount = model.ballotCount;
                  return Column(
                    children: [
                      if (ballotCount != null)
                        Text(
                          'All cast ballots: $ballotCount',
                          textScaleFactor: 1.5,
                        ),
                      CondorcetElectionResultWidget(result),
                    ],
                  );
                },
              ),
              if (voteModel != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: valueProviderConsumer<VoteModel<String>>(
                      value: voteModel,
                      builder: _buildLists,
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

Widget _buildLists(BuildContext _, VoteModel<String> model, __) => Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _sortedListHeader('My Rank'),
              Expanded(
                child: _createOrEmpty<String>(
                  model.rank,
                  'Press + on an item to add it.',
                  (items) => rankList(model, items),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _sortedListHeader('Remaining options'),
              Expanded(
                child: _createOrEmpty<String>(
                  model.remainingCandidates.toList(),
                  'You have ranked all items.',
                  (items) => remainingOptions(model, items),
                ),
              ),
            ],
          ),
        )
      ],
    );

Widget _sortedListHeader(String title) => Text(
      title,
      textScaleFactor: 1.2,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );

Widget rankList(VoteModel<String> model, Iterable<String> items) =>
    ReorderableListView(
      padding: _listViewPadding,
      onReorder: model.reorderVotes,
      children: [
        for (var item in items)
          GestureDetector(
            key: ValueKey(item),
            child: Card(
              margin: const EdgeInsets.all(2),
              child: ListTile(
                key: ValueKey(item),
                title: Text(
                  item,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_sharp),
                      tooltip: 'Remove',
                      onPressed: () => model.removeCandidate(item),
                    ),
                    const SizedBox(width: 10)
                  ],
                ),
              ),
            ),
            onDoubleTap: () => model.removeCandidate(item),
          )
      ],
    );

Widget remainingOptions(VoteModel<String> model, Iterable<String> items) =>
    ListView(
      controller: ScrollController(),
      padding: _listViewPadding,
      children: [
        for (var item in items)
          GestureDetector(
            child: Card(
              child: ListTile(
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline_sharp),
                  tooltip: 'Add',
                  onPressed: () => model.addCandidate(item),
                ),
              ),
            ),
            onDoubleTap: () => model.addCandidate(item),
          )
      ],
    );

Widget _createOrEmpty<T>(
  List<T> items,
  String emptyMessage,
  Widget Function(Iterable<T> items) creator,
) {
  if (items.isEmpty) {
    return Container(
      alignment: Alignment.topCenter,
      padding: _listViewPadding,
      child: Text(emptyMessage),
    );
  }
  return creator(items);
}

const _listViewPadding = EdgeInsets.all(8);
