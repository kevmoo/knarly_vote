import 'package:knarly_common/knarly_common.dart';
import 'package:vote/vote.dart' as vote;

Object getVoteJson(Election election, List<Ballot> ballots) {
  final voteBallots = ballots.map((e) => vote.RankedBallot(e.rank)).toList();

  final condorcet = vote.CondorcetElection(
    voteBallots,
    candidates: election.candidates,
  );

  return condorcet.pairs
      .map(
        (e) => {
          '1': e.candidate1,
          '2': e.candidate2,
          if ((e.firstOverSecond ?? 0) > 0) '1over2': e.firstOverSecond,
          if ((e.secondOverFirst ?? 0) > 0) '2over1': e.secondOverFirst,
          if ((e.ties ?? 0) > 0) 'ties': e.ties,
        },
      )
      .toList();
}
