import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:knarly_common/knarly_common.dart';
import 'package:vote/vote.dart';

class ElectionResultModel extends ChangeNotifier
    implements ValueListenable<CondorcetElectionResult<String>?> {
  final String electionId;
  StreamSubscription? _subscription;
  CondorcetElectionResult<String>? _value;

  int? _ballotCount;

  /// The number of cast ballots or `null` if still waiting for results.
  int? get ballotCount => _ballotCount;

  ElectionResultModel(this.electionId);

  void _listen(DocumentSnapshot event) {
    final data = event.data() as Map<String, dynamic>?;

    if (data == null) {
      // No votes have been cast!
      _value = null;
      _ballotCount = 0;
    } else {
      _value = _decode(data);
      _ballotCount = data['ballotCount'] as int?;
    }

    notifyListeners();
  }

  @override
  CondorcetElectionResult<String>? get value => _value;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_subscription == null && hasListeners) {
      _subscription = FirebaseFirestore.instance
          .doc(electionResultPath(electionId))
          .snapshots()
          .listen(_listen);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_subscription != null && !hasListeners) {
      _subscription?.cancel();
      _subscription = null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  String toString() => 'ElectionResultModel $electionId ($hashCode)';
}

CondorcetElectionResult<String> _decode(Map<String, dynamic> map) {
  final places = (map['places'] as List)
      .cast<Map<String, dynamic>>()
      .map(
        (e) => _MyPair._internal(
          e['1'] as String,
          e['2'] as String,
          e['1over2'] as int? ?? 0,
          e['2over1'] as int? ?? 0,
          e['ties'] as int? ?? 0,
        ),
      )
      .toSet();

  return CondorcetElectionResult.fromPairs(places);
}

class _MyPair implements CondorcetPair<String> {
  @override
  @override
  final String candidate1, candidate2;

  @override
  final int? firstOverSecond;
  @override
  final int? secondOverFirst;

  /// Number of ballots where neither candidate was listed
  @override
  final int? ties;

  const _MyPair._internal(
    this.candidate1,
    this.candidate2,
    this.firstOverSecond,
    this.secondOverFirst,
    this.ties,
  );

  @override
  String? get winner {
    if (firstOverSecond! > secondOverFirst!) {
      return candidate1;
    } else if (secondOverFirst! > firstOverSecond!) {
      return candidate2;
    } else {
      assert(isTie);
      return null;
    }
  }

  @override
  bool get isTie => firstOverSecond == secondOverFirst;

  @override
  bool matches(String can1, String can2) {
    assert(can1 != can2, 'can1 and can2 must be different');

    if (can1.compareTo(can2) > 0) {
      final temp = can2;
      can2 = can1;
      can1 = temp;
    }

    return (candidate1 == can1) && (candidate2 == can2);
  }

  // sometimes it's nice to deal w/ a properly aligned pair
  @override
  CondorcetPair<String> flip(String firstCandidate) {
    assert(firstCandidate == candidate1 || firstCandidate == candidate2);

    var can2 = firstCandidate == candidate1 ? candidate2 : candidate1;

    var flipped = false;
    if (firstCandidate.compareTo(can2) > 0) {
      final temp = can2;
      can2 = firstCandidate;
      firstCandidate = temp;
      flipped = true;
    }

    assert(firstCandidate == candidate1, 'can1');
    assert(can2 == candidate2, 'can2');

    if (flipped) {
      return _MyPair._internal(
        can2,
        firstCandidate,
        secondOverFirst,
        firstOverSecond,
        ties,
      );
    } else {
      return this;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is CondorcetPair &&
      candidate1 == other.candidate1 &&
      candidate2 == other.candidate2;

  @override
  int get hashCode => candidate1.hashCode * 37 ^ candidate2.hashCode;

  @override
  String toString() => '($candidate1, $candidate2)';

  @override
  int compareTo(covariant _MyPair other) {
    var value = candidate1.compareTo(other.candidate1);
    if (value == 0) {
      value = candidate2.compareTo(other.candidate2);
    }
    return value;
  }
}
