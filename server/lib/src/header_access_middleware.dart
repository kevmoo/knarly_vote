import 'dart:async';

import 'package:shelf/shelf.dart';

final _headersZoneKey = Object();

Map<String, String>? get currentRequestHeaders =>
    Zone.current[_headersZoneKey] as Map<String, String>?;

Middleware requestHeaderAccessMiddleware() =>
    (Handler handler) => (Request request) async => await runZoned(
          () async => await handler(request),
          zoneValues: {_headersZoneKey: request.headers},
        );
