import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';

part 'service_config.g.dart';

@JsonSerializable(anyMap: true, checked: true, disallowUnrecognizedKeys: true)
class ServiceConfig {
  final String appId;

  /// https://firebase.google.com/docs/projects/api-keys
  final String apiKey;

  /// https://firebase.google.com/docs/projects/learn-more#project-id
  final String projectId;

  /// https://cloud.google.com/identity-platform/docs/show-custom-domain
  final String authDomain;

  /// The `LOCATION_ID` need as part of the task request parent:
  /// `projects/PROJECT_ID/locations/LOCATION_ID/queues/QUEUE_ID`.
  final String electionUpdateTaskLocation;

  /// The `QUEUE_ID` need as part of the task request parent:
  /// `projects/PROJECT_ID/locations/LOCATION_ID/queues/QUEUE_ID`.
  final String electionUpdateTaskQueueId;

  /// The service account email needed to create a signed
  /// [OpenID Connect token](https://developers.google.com/identity/protocols/OpenIDConnect).
  final String serviceAccountEmail;

  /// The host where the task request should be sent.
  final String webHost;

  const ServiceConfig({
    required this.projectId,
    required this.authDomain,
    required this.apiKey,
    required this.electionUpdateTaskLocation,
    required this.electionUpdateTaskQueueId,
    required this.appId,
    required this.serviceAccountEmail,
    required this.webHost,
  });

  factory ServiceConfig.fromJson(Map json) => _$ServiceConfigFromJson(json);

  static late final ServiceConfig instance = _openConfig();

  Map<String, String> firebaseConfig() => {
        'apiKey': apiKey,
        'authDomain': authDomain,
        'projectId': projectId,
        //'databaseURL': 'https://$projectId.firebaseio.com',
        //'storageBucket': '$projectId.appspot.com',
        //'messagingSenderId': '????',
        'appId': appId,
      };

  Map<String, dynamic> toJson() => _$ServiceConfigToJson(this);

  static ServiceConfig _openConfig() {
    final envValues = Map.fromEntries(
      _configKeys.map((e) {
        final value = Platform.environment[e];
        return value == null ? null : MapEntry<String, String>(e, value);
      }).whereType<MapEntry<String, String>>(),
    );

    if (envValues.length == _configKeys.length) {
      return ServiceConfig.fromJson(envValues);
    }

    if (envValues.isNotEmpty) {
      print('Only have some of the required environment variables.');
      print('  We have: ${envValues.keys.join(',')}');
      print('  Missing: ${_configKeys.difference(envValues.keys.toSet())}');
      print('  Going to try to open the yaml file...');
    }

    return openConfig();
  }

  static ServiceConfig openConfig() {
    final file = File('server_config.yaml');

    final text = file.readAsStringSync();

    final yaml = loadYaml(text) as YamlMap;

    return ServiceConfig.fromJson(yaml);
  }
}

const _configKeys = {
  'apiKey',
  'projectId',
  'authDomain',
  'electionUpdateTaskLocation',
  'electionUpdateTaskQueueId',
  'serviceAccountEmail',
  'webHost',
  'appId',
};
