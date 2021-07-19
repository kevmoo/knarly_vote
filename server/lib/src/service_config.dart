import 'dart:io';

import 'package:yaml/yaml.dart';

class ServiceConfig {
  /// https://firebase.google.com/docs/projects/api-keys
  final String apiKey;

  /// https://firebase.google.com/docs/projects/learn-more#project-id
  final String projectId;

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
    required this.apiKey,
    required this.electionUpdateTaskLocation,
    required this.electionUpdateTaskQueueId,
    required this.serviceAccountEmail,
    required this.webHost,
  });

  static late final ServiceConfig instance = _openConfig();

  Map<String, String> firebaseConfig() => {
        'apiKey': apiKey,
        'authDomain': '$projectId.firebaseapp.com',
        'projectId': projectId,
        //'databaseURL': 'https://$projectId.firebaseio.com',
        //'storageBucket': '$projectId.appspot.com',
        //'messagingSenderId': '????',
        //'appId': '????',
        //'measurementId': '???',
      };

  // TODO: get rid of hard-coded values.
  static ServiceConfig _openConfig() {
    final file = File('server_config.yaml');

    final text = file.readAsStringSync();

    final yaml = (loadYaml(text) as YamlMap).cast<String, String>();

    String val(String key) {
      final value = yaml[key];
      if (value == null) {
        throw StateError('We do not have key "$key".');
      }
      return value;
    }

    return ServiceConfig(
      apiKey: val('apiKey'),
      projectId: val('projectId'),
      electionUpdateTaskLocation: val('electionUpdateTaskLocation'),
      electionUpdateTaskQueueId: val('electionUpdateTaskQueueId'),
      serviceAccountEmail: val('serviceAccountEmail'),
      webHost: val('webHost'),
    );
  }
}
