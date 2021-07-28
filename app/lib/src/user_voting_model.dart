import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:knarly_common/knarly_common.dart';

import 'authenticated_user_mixin.dart';
import 'election_result_model.dart';
import 'network_exception.dart';
import 'vote_model.dart';

class UserVotingModel extends ChangeNotifier with AuthenticatedUserMixin {
  @override
  final User user;

  Election? _election;
  ElectionResultModel? _electionResultModel;

  ElectionResultModel? get electionResultModel => _electionResultModel;

  UserVotingModelState _state = UserVotingModelState.justCreated;

  VoteModel<String>? _voteModel;

  bool _switchingStates = false;

  UserVotingModel(this.user) {
    _switchState(UserVotingModelState.requestingElections);
  }

  UserVotingModelState get state => _state;

  VoteModel<String>? get voteModel => _voteModel;

  String? get electionName => _election?.name;

  void _switchState(UserVotingModelState requestedState) {
    assert(!_switchingStates);
    _switchingStates = true;
    try {
      // Validate the transition!
      final validRequestedStates = _validTransitions[_state];
      if (validRequestedStates == null ||
          !validRequestedStates.contains(requestedState)) {
        throw StateError(
          'Not valid to transition from `${_state.name}` to '
          '`${requestedState.name}`.',
        );
      }

      switch (requestedState) {
        case UserVotingModelState.requestingElections:
          assert(_state == UserVotingModelState.justCreated);

          _runAsync(() async {
            final uri = Uri.parse('api/elections/');
            final response = await get(uri);
            if (response.statusCode != 200) {
              throw NetworkException(
                  'Bad response from service! ${response.statusCode}. '
                  '${response.body}',
                  statusCode: response.statusCode,
                  uri: uri);
            }
            final json = jsonDecode(response.body) as List;
            if (json.isEmpty) {
              throw StateError('No values returned!');
            }

            _election = Election.fromJson(json.first as Map<String, dynamic>);
            _electionResultModel = ElectionResultModel(_election!.id);
            _switchState(UserVotingModelState.updatingBallot);
          });

          break;

        case UserVotingModelState.updatingBallot:
          assert(
            _state == UserVotingModelState.requestingElections ||
                _state == UserVotingModelState.idle ||
                _state == UserVotingModelState.updatingBallot,
          );

          _runAsync(_stateToUpdatingBallots);
          break;
        case UserVotingModelState.idle:
          assert(
            _state == UserVotingModelState.updatingBallot ||
                _state == UserVotingModelState.idle,
            'The state is $_state',
          );
          assert(_voteModel != null);
          break;
        case UserVotingModelState.error:
          print('Reload the application, yo!');
          break;
        default:
          throw StateError(
            'Transition from `${_state.name}` to `${requestedState.name}` not '
            'implemented!',
          );
      }

      _state = requestedState;
      notifyListeners();
    } finally {
      assert(_switchingStates);
      _switchingStates = false;
    }
  }

  int _stackedUpdateBallotsCount = 0;

  Future<void> _stateToUpdatingBallots() async {
    assert(_state == UserVotingModelState.updatingBallot, '_state is $_state');
    final election = _election;
    if (election == null) {
      throw StateError('Election must not be null!');
    }

    final uri = Uri.parse('api/ballots/${election.id}/');

    final newRank = _voteModel?.rank.toList();

    _stackedUpdateBallotsCount++;
    try {
      final response = newRank == null
          ? await get(uri)
          : await put(
              uri,
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(newRank),
            );
      if (_stackedUpdateBallotsCount > 1) {
        // Only want to update "the world" if this is the last update to go
        // through – otherwise we have timing issues!
        return;
      }
      if (response.statusCode != 200) {
        throw NetworkException(
          'Bad response from service! ${response.statusCode}. '
          '${response.body}',
          statusCode: response.statusCode,
          uri: uri,
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final ballot = Ballot.fromJson(json);

      final currentModel = _voteModel;

      if (currentModel == null || !listEquals(currentModel.rank, ballot.rank)) {
        if (currentModel != null) {
          currentModel.removeListener(_onVoteModelChanged);
        }
        _voteModel = VoteModel(
          election.candidates,
          ballot.rank,
        )..addListener(_onVoteModelChanged);
      }
      _switchState(UserVotingModelState.idle);
    } finally {
      _stackedUpdateBallotsCount--;
    }
  }

  void _onVoteModelChanged() {
    _switchState(UserVotingModelState.updatingBallot);
  }

  void _runAsync(FutureOr<void> Function() func) {
    Timer.run(() async {
      try {
        await func();
      } catch (error) {
        print('Error during state ${_state.name}');
        _switchState(UserVotingModelState.error);
        rethrow;
      }
    });
  }

  @override
  void dispose() {
    _voteModel?.removeListener(_onVoteModelChanged);
    _voteModel?.dispose();
    super.dispose();
  }
}

const _validTransitions = {
  UserVotingModelState.justCreated: {
    UserVotingModelState.requestingElections,
  },
  UserVotingModelState.requestingElections: {
    UserVotingModelState.error,
    UserVotingModelState.updatingBallot,
  },
  UserVotingModelState.updatingBallot: {
    UserVotingModelState.error,
    UserVotingModelState.idle,
    UserVotingModelState.updatingBallot,
  },
  UserVotingModelState.idle: {
    UserVotingModelState.error,
    UserVotingModelState.updatingBallot,
  },
};

enum UserVotingModelState {
  justCreated,
  requestingElections,
  idle,
  updatingBallot,
  error,
}

extension UserVotingModelStateExtension on UserVotingModelState {
  String get name => toString().split('.').last;
}
