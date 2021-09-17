// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'election.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ElectionPreview _$ElectionPreviewFromJson(Map<String, dynamic> json) =>
    ElectionPreview(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ElectionPreviewToJson(ElectionPreview instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  return val;
}

Election _$ElectionFromJson(Map<String, dynamic> json) => Election(
      id: json['id'] as String,
      name: json['name'] as String,
      candidates:
          (json['candidates'] as List<dynamic>).map((e) => e as String).toSet(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ElectionToJson(Election instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('description', instance.description);
  val['candidates'] = instance.candidates.toList();
  return val;
}

Ballot _$BallotFromJson(Map<String, dynamic> json) => Ballot(
      (json['rank'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BallotToJson(Ballot instance) => <String, dynamic>{
      'rank': instance.rank,
    };
