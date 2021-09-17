import 'package:flutter/material.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:provider/provider.dart';
import 'package:vote_widgets/vote_widgets.dart';

import '../auth_model.dart';
import '../election_result_model.dart';
import '../user_voting_model.dart';
import '../vote_model.dart';

class VoteWidget extends StatelessWidget {
  final FirebaseAuthModel _user;
  final Election _data;

  VoteWidget(this._user, this._data);

  @override
  Widget build(BuildContext context) =>
      _createProviderConsumer<UserVotingModel>(
        create: (_) => UserVotingModel(_user, _data),
        builder: (context, model, __) {
          final electionModel = model.electionResultModel;
          final voteModel = model.voteModel;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'State: ${model.state.name}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              if (model.state == UserVotingModelState.error)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Check out the dev console. Reload?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).errorColor,
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
              _valueProviderConsumer<ElectionResultModel>(
                value: electionModel,
                builder: (_, model, __) {
                  final ballotCount = model.ballotCount;
                  final result = model.value;
                  if (result == null) {
                    assert(ballotCount == null || ballotCount == 0);
                    if (ballotCount == 0) {
                      return const Text(
                        'No votes have been cast.',
                      );
                    }
                    return const Text(
                      'Waiting for result to be calculated...',
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _valueProviderConsumer<VoteModel<String>>(
                    value: voteModel,
                    builder: _buildLists,
                  ),
                ),
            ],
          );
        },
      );
}

Widget _buildLists(BuildContext _, VoteModel<String> model, __) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sortedListHeader('My Rank'),
              _createOrEmpty<String>(
                model.rank,
                'Press + on an item to add it.',
                (items) => _rankList(model, items),
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sortedListHeader('Remaining options'),
              _createOrEmpty<String>(
                model.remainingCandidates.toList(),
                'You have ranked all items.',
                (items) => _remainingOptions(model, items),
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

Widget _rankList(VoteModel<String> model, Iterable<String> items) =>
    ReorderableListView(
      shrinkWrap: true,
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

Widget _remainingOptions(VoteModel<String> model, Iterable<String> items) =>
    Column(
      mainAxisSize: MainAxisSize.min,
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

Widget _createProviderConsumer<T extends ChangeNotifier>({
  required Create<T> create,
  required Widget Function(
    BuildContext context,
    T value,
    Widget? child,
  )
      builder,
}) =>
    ChangeNotifierProvider<T>(
      create: create,
      child: Consumer<T>(builder: builder),
    );

Widget _valueProviderConsumer<T extends ChangeNotifier>({
  required T value,
  required Widget Function(
    BuildContext context,
    T value,
    Widget? child,
  )
      builder,
}) =>
    ChangeNotifierProvider<T>.value(
      value: value,
      child: Consumer<T>(builder: builder),
    );
