import 'dart:io';

import 'package:knarly_server/src/service_config.dart';

Future<void> main(List<String> args) async {
  final serviceName = args.single;

  final config = ServiceConfig.openConfig();

  final settings =
      config.toJson().entries.map((e) => '${e.key}=${e.value}').join(',');

  final result = await Process.start(
    'gcloud',
    [
      'run',
      'services',
      'update',
      serviceName,
      '--set-env-vars=$settings',
    ],
    mode: ProcessStartMode.inheritStdio,
  );

  print('Exit code: ${await result.exitCode}');

  await Process.start(
    'gcloud',
    [
      'run',
      'services',
      'describe',
      serviceName,
      '--format=yaml',
    ],
    mode: ProcessStartMode.inheritStdio,
  );
}
