import 'dart:convert';

import 'package:jose/jose.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_jwt_auth/shelf_jwt_auth.dart';
import 'package:shelf_router/shelf_router.dart';

import 'cloud_headers.dart';
import 'election_storage.dart';
import 'firestore_election_storage.dart';
import 'service_config.dart';
import 'service_exception.dart';

part 'service.g.dart';

class VoteService {
  final ElectionStorage _storage;

  final ServiceConfig config;

  String get _projectId => config.projectId;

  final _store = JsonWebKeyStore();

  VoteService({
    required ElectionStorage storage,
    required this.config,
    required Iterable<Uri> keySetUrls,
  }) : _storage = storage {
    for (var uri in keySetUrls) {
      _store.addKeySetUrl(uri);
    }
  }

  @Route.get('/api/config.js')
  Response getConfig(Request request) => Response.ok(
        '''
firebase.initializeApp(${jsonEncode(config.firebaseConfig())});
firebase.analytics();
''',
        headers: {
          'content-type': 'application/javascript',
          'cache-control': 'public',
        },
      );

  @Route.get('/api/elections/')
  Future<Response> listElections(Request request) async {
    final userId = await _jwtSubjectFromRequest(request);

    return _okJsonResponse(await _storage.listElections(userId));
  }

  @Route.get('/api/elections/<electionId>/')
  Future<Response> getElection(Request request, String electionId) async {
    final userId = await _jwtSubjectFromRequest(request);

    return _okJsonResponse(await _storage.getElection(userId, electionId));
  }

  @Route.get('/api/ballots/<electionId>/')
  Future<Response> ballot(Request request, String electionId) async {
    final userId = await _jwtSubjectFromRequest(request);

    return _okJsonResponse(await _storage.getBallot(userId, electionId));
  }

  @Route.put('/api/ballots/<electionId>/')
  Future<Response> updateBallot(Request request, String electionId) async {
    final userId = await _jwtSubjectFromRequest(request);

    final newRank =
        (jsonDecode(await request.readAsString()) as List).cast<String>();

    // TODO: validate the rank!
    //  no duplicates, every item is in the parent source, etc etc

    final updateResult =
        await _storage.updateBallot(userId, electionId, newRank);

    return _okJsonResponse(updateResult);
  }

  @Route.post('/api/elections/<electionId>/update')
  Future<Response> updateElectionResult(
    Request request,
    String electionId,
  ) async {
    final queueName = request.headers[googleCloudTaskQueueName];

    if (queueName != config.electionUpdateTaskQueueId) {
      throw ServiceException(
        ServiceExceptionKind.badUpdateRequest,
        'Bad value for `$googleCloudTaskQueueName` header. Got "$queueName", '
        'expected "${config.electionUpdateTaskQueueId}"',
      );
    }

    if (request.requestedUri.isScheme('https')) {
      await _jwtFromRequest(request, expectServiceRequest: true);
    } else {
      print('* Not HTTPS - assuming local request to ${request.requestedUri}');
    }

    await _storage.updateElection(electionId);

    return Response.ok('Update succeeded for election ID $electionId');
  }

  Router get router => _$VoteServiceRouter(this);

  Future<String> _jwtSubjectFromRequest(Request request) async {
    final jwt = await _jwtFromRequest(request, expectServiceRequest: false);

    final hasAudience = jwt.claims.audience?.contains(_projectId);

    if (hasAudience != true) {
      throw ServiceException.authorizationTokenValidation(
        'Audience does not contain expected project "$_projectId".',
      );
    }

    return jwt.claims.subject!;
  }

  Future<JsonWebToken> _jwtFromRequest(
    Request request, {
    required bool expectServiceRequest,
  }) async {
    JsonWebToken? jwt;
    try {
      jwt = await tokenFromRequest(request, _store);
    } catch (error, stack) {
      throw ServiceException(
        ServiceExceptionKind.authorizationTokenValidation,
        'Error parsing the authorization header.',
        innerError: error,
        innerStack: stack,
      );
    }

    if (jwt == null) {
      throw ServiceException.authorizationTokenValidation(
        'No authorization information present.',
      );
    }

    if (jwt.isVerified == true) {
      if (expectServiceRequest) {
        if (jwt.claims['email_verified'] == true &&
            jwt.claims['email'] == config.serviceAccountEmail) {
          return jwt;
        }

        print(prettyJson(jwt.claims));
        throw ServiceException.authorizationTokenValidation(
          'Expected a verified email associated with the configured service '
          'account.',
        );
      }
      return jwt;
    }

    throw ServiceException.authorizationTokenValidation(
      'Token could not be verified.',
    );
  }
}

Response _okJsonResponse(Object json) => Response.ok(
      jsonEncode(json),
      headers: {
        'Content-Type': 'application/json',
      },
    );
