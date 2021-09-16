import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

part 'election.g.dart';

@JsonSerializable(explicitToJson: true)
class PlaceData {
  final int place;
  final List<String> candidates;

  PlaceData(this.place, this.candidates);

  factory PlaceData.fromJson(Map<String, dynamic> json) =>
      _$PlaceDataFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceDataToJson(this);
}

@JsonSerializable(includeIfNull: false)
class ElectionPreview {
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

  ElectionPreview({
    required this.id,
    required this.name,
    this.description,
  });

  factory ElectionPreview.fromJson(Map<String, dynamic> json) =>
      _$ElectionPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$ElectionPreviewToJson(this);
}

@JsonSerializable(includeIfNull: false)
class Election extends ElectionPreview {
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

  @override
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
