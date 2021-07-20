// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: require_trailing_commas

part of 'service_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceConfig _$ServiceConfigFromJson(Map json) => $checkedCreate(
      'ServiceConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          allowedKeys: const [
            'apiKey',
            'projectId',
            'electionUpdateTaskLocation',
            'electionUpdateTaskQueueId',
            'serviceAccountEmail',
            'webHost'
          ],
        );
        final val = ServiceConfig(
          projectId: $checkedConvert('projectId', (v) => v as String),
          apiKey: $checkedConvert('apiKey', (v) => v as String),
          electionUpdateTaskLocation:
              $checkedConvert('electionUpdateTaskLocation', (v) => v as String),
          electionUpdateTaskQueueId:
              $checkedConvert('electionUpdateTaskQueueId', (v) => v as String),
          serviceAccountEmail:
              $checkedConvert('serviceAccountEmail', (v) => v as String),
          webHost: $checkedConvert('webHost', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ServiceConfigToJson(ServiceConfig instance) =>
    <String, dynamic>{
      'apiKey': instance.apiKey,
      'projectId': instance.projectId,
      'electionUpdateTaskLocation': instance.electionUpdateTaskLocation,
      'electionUpdateTaskQueueId': instance.electionUpdateTaskQueueId,
      'serviceAccountEmail': instance.serviceAccountEmail,
      'webHost': instance.webHost,
    };
