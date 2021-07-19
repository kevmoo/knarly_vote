import 'dart:collection';

import 'package:flutter/foundation.dart';

class VoteModel<T> extends ChangeNotifier {
  final Set<T> candidates;
  final List<T> _rank;
  final UnmodifiableListView<T> rank;

  VoteModel(this.candidates, this._rank)
      : assert(_rank.length == _rank.toSet().length),
        assert(_rank.every(candidates.contains)),
        rank = UnmodifiableListView(_rank);

  Iterable<T> get remainingCandidates =>
      candidates.where((element) => !_rank.contains(element));

  void reorderVotes(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _rank.removeAt(oldIndex);
    _rank.insert(newIndex, item);
    notifyListeners();
  }

  void addCandidate(T candidate) {
    assert(candidates.contains(candidate));
    assert(!_rank.contains(candidate));
    _rank.add(candidate);
    notifyListeners();
  }

  void removeCandidate(T candidate) {
    assert(candidates.contains(candidate));
    assert(_rank.contains(candidate));
    _rank.remove(candidate);
    notifyListeners();
  }
}
