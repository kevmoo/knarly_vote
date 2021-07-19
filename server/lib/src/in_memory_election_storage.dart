import 'dart:async';

import 'package:knarly_client/knarly_client.dart';

import 'election_storage.dart';
import 'service_exception.dart';

class InMemoryElectionStorage implements ElectionStorage {
  final _inMemoryStorage = <String, List<String>>{};

  @override
  List<Election> listElection(String userId) => [_defaultElection];

  @override
  Ballot getBallot(String userId, String electionId) {
    if (electionId != _defaultElection.id) {
      throw ServiceException(
        ServiceExceptionKind.resourceNotFound,
        'No election "$electionId" exists for user "$userId".',
      );
    }

    return Ballot(
      _inMemoryStorage[_mapKey(userId, electionId)] ?? [],
    );
  }

  @override
  Ballot updateBallot(
    String userId,
    String electionId,
    List<String> rank,
  ) {
    if (electionId != _defaultElection.id) {
      throw ServiceException(
        ServiceExceptionKind.resourceNotFound,
        'No election "$electionId" exists for user "$userId".',
      );
    }

    final mapKey = _mapKey(userId, electionId);
    if (rank.isEmpty) {
      _inMemoryStorage.remove(mapKey);
    } else {
      _inMemoryStorage[mapKey] = rank;
    }

    return Ballot(rank);
  }

  @override
  FutureOr<void> updateElection(String electionId) {
    // TODO: implement updateElection
    throw UnimplementedError();
  }
}

String _mapKey(String userId, String electionId) =>
    // Using a `/` here, since it's not a valid firebase ID
    '$electionId/$userId';

final _defaultElection = Election(
  id: 'test1234',
  name: 'Pizza!',
  candidates: {
    'beef and mushroom',
    'cheese',
    'pepperoni',
    'pineapple',
    'meat lovers',
  },
);
