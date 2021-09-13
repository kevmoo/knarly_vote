import 'dart:convert';

import 'package:jose/jose.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_jwt_auth/shelf_jwt_auth.dart';
import 'package:shelf_router/shelf_router.dart';

import 'election_storage.dart';
import 'firestore_election_storage.dart';
import 'service_config.dart';
import 'service_exception.dart';
import 'shared.dart';

part 'service.g.dart';

class VoteService {
  final ElectionStorage _storage;

  final ServiceConfig config;

  String get _projectId => config.projectId;

  VoteService({
    required ElectionStorage storage,
    required this.config,
  }) : _storage = storage;

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

    return _okJsonResponse(await _storage.listElection(userId));
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
    const queueNameHeader = 'x-cloudtasks-queuename';

    final queueName = request.headers[queueNameHeader];

    if (queueName == null) {
      // TODO: this should be an error!
      print('Missing the $queueNameHeader!');
    } else if (queueName != config.electionUpdateTaskQueueId) {
      // TODO: this should be an error!
      print(
        'We have the wrong task queue. Got "$queueName", expected '
        '"${config.electionUpdateTaskQueueId}"',
      );
    }

    try {
      final jwt = await _jwtFromRequest(request);
      print(prettyJson(jwt.claims));
    } catch (e) {
      // TODO: this should be an error!
      print(
        [
          '--',
          'Could not validate the authorization header',
          '--',
        ].join('\n'),
      );
      debugPrintRequestHeaders(request);
    }

    await _storage.updateElection(electionId);

    return Response.ok('Update succeeded for election ID $electionId');
  }

  Router get router => _$VoteServiceRouter(this);

  Future<String> _jwtSubjectFromRequest(Request request) async {
    final jwt = await _jwtFromRequest(request);

    final hasAudience = jwt.claims.audience?.contains(_projectId);

    if (hasAudience != true) {
      throw ServiceException.firebaseTokenValidation(
        'Audience does not contain expected project "$_projectId".',
      );
    }

    return jwt.claims.subject!;
  }

  Future<JsonWebToken> _jwtFromRequest(Request request) async {
    final jwt = await tokenFromRequest(request, _store);

    if (jwt == null) {
      throw ServiceException.firebaseTokenValidation('Could not validate auth');
    }

    assert(jwt.isVerified == true);

    return jwt;
  }

  final _store = JsonWebKeyStore()
    ..addKeySetUrl(
      Uri.parse(
        'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
      ),
    )
    // TODO: should be getting this from
    //  https://accounts.google.com/.well-known/openid-configuration
    //  via jwks_uri – per https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig
    // Feature request for pkg:jose:https://github.com/appsup-dart/jose/issues/32
    ..addKeySetUrl(
      Uri.parse(
        'https://www.googleapis.com/oauth2/v3/certs',
      ),
    );
}

Response _okJsonResponse(Object json) => Response.ok(
      jsonEncode(json),
      headers: {
        'Content-Type': 'application/json',
      },
    );
