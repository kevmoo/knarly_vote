import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'election.g.dart';

abstract class _ElectionCore {
  // TODO: id MUST be a valid URI component
  final String id;

  // owner info
  // TODO: multiple owners

  // * friendly name
  // min/max length, etc
  final String name;

  final String? description;

  // state: draft, open, closed

  // ** Data validation **

  // TODO: allowed twitter users?
  // TODO: restrict to one auth provider or one email domain?

  _ElectionCore({
    required this.id,
    required this.name,
    this.description,
  });
}

@JsonSerializable(includeIfNull: false)
class ElectionPreview extends _ElectionCore {
  final bool userVoted;
  final int ballotCount;

  ElectionPreview({
    required String id,
    required String name,
    required this.userVoted,
    required this.ballotCount,
    String? description,
  }) : super(id: id, name: name, description: description);

  factory ElectionPreview.fromJson(Map<String, dynamic> json) =>
      _$ElectionPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$ElectionPreviewToJson(this);
}

@JsonSerializable(includeIfNull: false)
class Election extends _ElectionCore {
  // candidates (String list of allowed values)
  final Set<String> candidates;

  Election({
    required String id,
    required String name,
    required Set<String> candidates,
    String? description,
  })  : candidates = Set.unmodifiable(
          candidates.toList()..sort(compareAsciiLowerCaseNatural),
        ),
        super(id: id, name: name, description: description) {
    _validCandidates(candidates, 'candidates');
  }

  factory Election.fromJson(Map<String, dynamic> json) =>
      _$ElectionFromJson(json);

  Map<String, dynamic> toJson() => _$ElectionToJson(this);
}

// ** Security concerns **
// Can only be created/updated if parent election is open
// Contents of rank must only be members of parent candidates
@JsonSerializable()
class Ballot {
  // parent election is implied
  // user_id (the person who "cast" the ballot)
  // rank (String list of candidate values)
  final List<String> rank;

  Ballot(this.rank) {
    _validCandidates(rank, 'rank');
    if (rank.length != rank.toSet().length) {
      throw ArgumentError.value(
        rank,
        'rank',
        'Cannot contain duplicate values',
      );
    }
    // rank should be valid candidate items!
    // no dupes!
  }

  factory Ballot.fromJson(Map<String, dynamic> json) => _$BallotFromJson(json);

  Map<String, dynamic> toJson() => _$BallotToJson(this);

  @override
  String toString() => 'Ballot(${rank.map((e) => '"$e"').join(', ')})';
}

void _validCandidates(Iterable<String> candidates, String argName) {
  for (var candidate in candidates) {
    if (candidate.isEmpty) {
      throw ArgumentError.value(
        candidates,
        argName,
        'Candidate values cannot be empty.',
      );
    }
    if (candidate.trim() != candidate) {
      throw ArgumentError.value(
        candidates,
        argName,
        'Candidate values must not have leading or trailing whitespace.',
      );
    }
  }
}
