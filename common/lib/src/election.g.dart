// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'election.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceData _$PlaceDataFromJson(Map<String, dynamic> json) => PlaceData(
      json['place'] as int,
      (json['candidates'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$PlaceDataToJson(PlaceData instance) => <String, dynamic>{
      'place': instance.place,
      'candidates': instance.candidates,
    };

Election _$ElectionFromJson(Map<String, dynamic> json) => Election(
      id: json['id'] as String,
      name: json['name'] as String,
      candidates:
          (json['candidates'] as List<dynamic>).map((e) => e as String).toSet(),
    );

Map<String, dynamic> _$ElectionToJson(Election instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'candidates': instance.candidates.toList(),
    };

Ballot _$BallotFromJson(Map<String, dynamic> json) => Ballot(
      (json['rank'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BallotToJson(Ballot instance) => <String, dynamic>{
      'rank': instance.rank,
    };
