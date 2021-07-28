import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:knarly_common/knarly_common.dart';

import 'election_result_model.dart';
import 'vote_model.dart';

class ServerVoteModel extends ChangeNotifier {
  final User _user;
  String? _firebaseIdToken;
  Election? _election;
  ElectionResultModel? _electionResultModel;

  ElectionResultModel? get electionResultModel => _electionResultModel;

  ServerVoteModelState _state = ServerVoteModelState.justCreated;

  VoteModel<String>? _voteModel;

  bool _switchingStates = false;

  ServerVoteModel(this._user) {
    _switchState(ServerVoteModelState.requestingToken);
  }

  ServerVoteModelState get state => _state;

  VoteModel<String>? get voteModel => _voteModel;

  String? get electionName => _election?.name;

  void _switchState(ServerVoteModelState requestedState) {
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
        case ServerVoteModelState.requestingToken:
          assert(_state == ServerVoteModelState.justCreated);

          _runAsync(() async {
            _firebaseIdToken = await _user.getIdToken();
            _switchState(ServerVoteModelState.requestingElections);
          });

          break;

        case ServerVoteModelState.requestingElections:
          assert(_state == ServerVoteModelState.requestingToken);
          assert(_firebaseIdToken != null);

          _runAsync(() async {
            final uri = Uri.parse('api/elections/');
            final response = await get(uri, headers: _requestHeaders);
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
            _switchState(ServerVoteModelState.updatingBallot);
          });

          break;

        case ServerVoteModelState.updatingBallot:
          assert(
            _state == ServerVoteModelState.requestingElections ||
                _state == ServerVoteModelState.idle ||
                _state == ServerVoteModelState.updatingBallot,
          );

          _runAsync(_stateToUpdatingBallots);
          break;
        case ServerVoteModelState.idle:
          assert(_state == ServerVoteModelState.updatingBallot);
          assert(_voteModel != null);
          break;
        case ServerVoteModelState.error:
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

  Future<void> _stateToUpdatingBallots() async {
    assert(_state == ServerVoteModelState.updatingBallot);
    final election = _election;
    if (election == null) {
      throw StateError('Election must not be null!');
    }

    final uri = Uri.parse('api/ballots/${election.id}/');

    final newRank = _voteModel?.rank.toList();

    final response = newRank == null
        ? await get(uri, headers: _requestHeaders)
        : await put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              ..._requestHeaders,
            },
            body: jsonEncode(newRank),
          );
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

    _switchState(ServerVoteModelState.idle);
  }

  void _onVoteModelChanged() {
    _switchState(ServerVoteModelState.updatingBallot);
  }

  void _runAsync(FutureOr<void> Function() func) {
    Timer.run(() async {
      try {
        await func();
      } catch (error) {
        print('Error during state ${_state.name}');
        _switchState(ServerVoteModelState.error);
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

  Map<String, String> get _requestHeaders =>
      {'Authorization': 'Bearer ${_firebaseIdToken!}'};
}

const _validTransitions = {
  ServerVoteModelState.justCreated: {ServerVoteModelState.requestingToken},
  ServerVoteModelState.requestingToken: {
    ServerVoteModelState.requestingElections,
    ServerVoteModelState.error,
  },
  ServerVoteModelState.requestingElections: {
    ServerVoteModelState.updatingBallot,
    ServerVoteModelState.error,
  },
  ServerVoteModelState.updatingBallot: {
    ServerVoteModelState.idle,
    ServerVoteModelState.error,
  },
  ServerVoteModelState.idle: {ServerVoteModelState.updatingBallot},
};

enum ServerVoteModelState {
  justCreated,
  requestingToken,
  requestingElections,
  idle,
  updatingBallot,
  error,
}

extension ServerVoteModelStateExtension on ServerVoteModelState {
  String get name => toString().split('.').last;
}

class NetworkException implements Exception {
  final String message;
  final Uri? uri;
  final int statusCode;

  NetworkException(this.message, {required this.statusCode, this.uri});

  @override
  String toString() => [
        'NetworkException: ($statusCode) $message',
        if (uri != null) '($uri)',
      ].join(' ');
}
