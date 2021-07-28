import 'dart:async';

import 'package:knarly_common/knarly_common.dart';

abstract class ElectionStorage {
  FutureOr<List<Election>> listElection(String userId);

  FutureOr<Ballot> getBallot(String userId, String electionId);

  FutureOr<Ballot> updateBallot(
    String userId,
    String electionId,
    List<String> rank,
  );

  FutureOr<void> updateElection(String electionId);
}
