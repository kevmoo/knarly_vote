import 'package:functions_framework/functions_framework.dart';
import 'package:shelf/shelf.dart';

import 'src/firestore_election_storage.dart';
import 'src/header_access_middleware.dart';
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

  return VoteService(storage: storage, config: config);
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
      } on ServiceException catch (e) {
        final clientErrorStatusCode = e.clientErrorStatusCode;
        if (clientErrorStatusCode != null) {
          return Response(clientErrorStatusCode, body: e.message);
        }
        rethrow;
      } catch (e, stack) {
        print(e);
        print(stack);
        rethrow;
      }
    };
