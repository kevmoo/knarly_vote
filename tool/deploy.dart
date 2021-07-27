#!/usr/bin/env dart

import 'dart:io';

Future<void> main() async {
  final proc = await Process.start(
    'flutter',
    ['build', 'web'],
    workingDirectory: 'app',
    mode: ProcessStartMode.inheritStdio,
  );

  final exit = await proc.exitCode;
  if (exit != 0) {
    return;
  }

  await Process.start(
    'firebase',
    ['deploy'],
    mode: ProcessStartMode.inheritStdio,
  );
}
