import 'package:functions_framework/functions_framework.dart';
import 'package:shelf/shelf.dart';
import 'package:stack_trace/stack_trace.dart';

import 'src/firestore_election_storage.dart';
import 'src/header_access_middleware.dart';
import 'src/openid_config.dart';
import 'src/service.dart';
import 'src/service_config.dart';
import 'src/service_exception.dart';

@CloudFunction()
Future<Response> function(Request request) async {
  final handler = _handler ??=
      _middleware.addMiddleware(requestHeaderAccessMiddleware()).addHandler(
            (await _createVoteService()).router,
          );

  return handler(request);
}

Future<VoteService> _createVoteService() async {
  final config = ServiceConfig.instance;
  final storage = await createElectionStorage(config);

  final _openIdConfigurationUris = [
    // See https://cloud.google.com/endpoints/docs/openapi/authenticating-users-firebase#configuring_your_openapi_document
    Uri.parse(
      'https://securetoken.google.com/${config.projectId}/.well-known/openid-configuration',
    ),
    Uri.parse(
      'https://accounts.google.com/.well-known/openid-configuration',
    ),
  ];

  final keySetUrls = await jwksUris(_openIdConfigurationUris);

  return VoteService(storage: storage, config: config, keySetUrls: keySetUrls);
}

Handler? _handler;

Handler _middleware(Handler innerHandler) => (Request request) async {
      try {
        var response = await innerHandler(request);

        if (!response.headers.containsKey('Cache-Control')) {
          response = response.change(
            headers: {
              'Cache-Control': 'no-store',
            },
          );
        }

        return response;
      } on ServiceException catch (e, stack) {
        final clientErrorStatusCode = e.clientErrorStatusCode;
        if (clientErrorStatusCode != null) {
          print(
            [
              if (e.innerError != null) e.innerError!,
              if (e.innerStack != null) Trace.from(e.innerStack!).terse,
              e,
              Trace.from(stack).terse,
            ].join('\n'),
          );
          return Response(
            clientErrorStatusCode,
            body: 'Bad request! Check the `x-cloud-trace-context` response '
                'header in the server logs to learn more.',
          );
        }
        rethrow;
      }
    };
