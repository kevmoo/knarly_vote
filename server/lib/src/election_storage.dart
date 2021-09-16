import 'dart:async';

import 'package:knarly_common/knarly_common.dart';

abstract class ElectionStorage {
  FutureOr<List<ElectionPreview>> listElections(String userId);

  FutureOr<Election> getElection(String userId, String electionId);

  FutureOr<Ballot> getBallot(String userId, String electionId);

  FutureOr<Ballot> updateBallot(
    String userId,
    String electionId,
    List<String> rank,
  );

  FutureOr<void> updateElection(String electionId);
}
