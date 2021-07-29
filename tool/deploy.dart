#!/usr/bin/env dart

import 'dart:io';

Future<void> main() async {
  final proc = await Process.start(
    'flutter',
    ['build', 'web'],
    workingDirectory: 'app',
    mode: ProcessStartMode.inheritStdio,
  );

  exitCode = await proc.exitCode;
}
