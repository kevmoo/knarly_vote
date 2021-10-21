import 'dart:async';
import 'dart:convert';

import 'package:googleapis/cloudtasks/v2.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:knarly_common/knarly_common.dart';

import 'cloud_headers.dart';
import 'election_storage.dart';
import 'firestore_extensions.dart';
import 'header_access_middleware.dart';
import 'service_config.dart';
import 'service_exception.dart';
import 'trace_context.dart';
import 'vote_logic.dart';

Future<FirestoreElectionStorage> createElectionStorage(
  ServiceConfig config,
) async {
  final client = await clientViaApplicationDefaultCredentials(
    scopes: [
      FirestoreApi.datastoreScope,
      // TODO: this should be exposed on the CloudTasks class!
      // https://github.com/google/googleapis.dart/issues/276
      'https://www.googleapis.com/auth/cloud-tasks',
    ],
  );

  return FirestoreElectionStorage(client, config);
}

class FirestoreElectionStorage implements ElectionStorage {
  final AutoRefreshingAuthClient _client;
  final FirestoreApi _firestore;
  final CloudTasksApi _tasks;
  final ServiceConfig config;

  FirestoreElectionStorage(this._client, this.config)
      : _firestore = FirestoreApi(_client),
        _tasks = CloudTasksApi(_client);

  @override
  Future<List<ElectionPreview>> listElections(String userId) async =>
      await _withTransaction<List<ElectionPreview>>(
        (p0) => _documents
            .listAll(
          _documentsPath,
          rootCollectionName,
          transaction: p0,
        )
            .asyncExpand((entry) async* {
          for (var doc in entry) {
            //
            // Figure out if the user voted
            //
            final userBallot = await _documents.getOrNull(
              _ballotPath(doc.id, userId),
              mask_fieldPaths: ['noop'],
            );
            final userVoted = userBallot != null;

            //
            // Find the total ballot count
            //
            final countData = await _documents.getOrNull(
              _resultsPath(doc.id),
              mask_fieldPaths: ['ballotCount'],
            );
            final ballotCount =
                countData?.literalValues!['ballotCount'] as int? ?? 0;

            final electionFields = doc.literalValues!;

            yield ElectionPreview(
              id: doc.id,
              name: electionFields['name'] as String,
              description: electionFields['description'] as String?,
              ballotCount: ballotCount,
              userVoted: userVoted,
            );
          }
        }).toList(),
      );

  @override
  FutureOr<Election> getElection(String userId, String electionId) async {
    final result =
        await _documents.getOrNull(_electionDocumentPath(electionId));

    if (result == null) {
      throw ServiceException(
        ServiceExceptionKind.resourceNotFound,
        'Election does not exist or user does not have access to it.',
      );
    }
    return result.toElection();
  }

  @override
  Future<Ballot> getBallot(String userId, String electionId) async {
    try {
      final document = await _documents.get(
        _ballotPath(electionId, userId),
      );

      return document.toBallot();
    } on DetailedApiRequestError catch (e) {
      if ((e.jsonResponse?['error'] as Map<String, dynamic>?)?['code'] == 404) {
        return Ballot([]);
      }
      rethrow;
    }
  }

  @override
  Future<Ballot> updateBallot(
    String userId,
    String electionId,
    List<String> rank,
  ) async {
    Ballot ballot;

    if (rank.isEmpty) {
      // If the rank is empty, just delete the ballot – not needed!
      await _documents.delete(_ballotPath(electionId, userId));

      ballot = Ballot([]);
    } else {
      final document = await _documents.patch(
        Document(fields: {'rank': valueFromLiteral(rank)}),
        _ballotPath(electionId, userId),
      );

      ballot = document.toBallot();
    }
    await _queElectionUpdateTask(electionId);
    return ballot;
  }

  @override
  Future<void> updateElection(String electionId) async {
    // download the election doc
    final electionDoc = await _documents.get(
      _electionDocumentPath(electionId),
    );

    final election = electionDoc.toElection();

    final ballots = await _withTransaction(
      (tx) => _documents
          .listAll(
            _electionDocumentPath(electionId),
            'ballots',
            transaction: tx,
          )
          .expand((ballotList) => ballotList.map((e) => e.toBallot()))
          .toList(),
    );

    if (ballots.isEmpty) {
      await _documents.delete(_resultsPath(electionId));
      return;
    }

    final condorcetJson = getVoteJson(election, ballots);

    await _documents.patch(
      Document(
        fields: {
          'places': valueFromLiteral(condorcetJson),
          'ballotCount': valueFromLiteral(ballots.length),
        },
      ),
      _resultsPath(electionId),
    );
  }

  Future<void> _queElectionUpdateTask(String electionId) async {
    final updateUri = '${config.webHost}/api/elections/$electionId/update';

    if (updateUri.startsWith('https')) {
      final traceParent = currentRequestHeaders?[traceParentHeaderName];

      await _tasks.projects.locations.queues.tasks.create(
        CreateTaskRequest(
          task: Task(
            httpRequest: HttpRequest(
              url: updateUri,
              oidcToken: OidcToken(
                serviceAccountEmail: config.serviceAccountEmail,
              ),
              headers: traceParent == null
                  ? null
                  : {
                      traceParentHeaderName:
                          TraceContext.parse(traceParent).randomize().toString()
                    },
            ),
          ),
        ),
        'projects/${config.projectId}/locations/${config.electionUpdateTaskLocation}/queues/${config.electionUpdateTaskQueueId}',
      );
    } else {
      await http.post(
        Uri.parse(updateUri),
        headers: {
          googleCloudTaskQueueName: config.electionUpdateTaskQueueId,
        },
      );
    }
  }

  void close() {
    _client.close();
  }

  String get _databaseId => 'projects/${config.projectId}/databases/(default)';

  String get _documentsPath => '$_databaseId/documents';

  String _resultsPath(String electionId) =>
      '$_documentsPath/${electionResultPath(electionId)}';

  String _electionDocumentPath(String electionId) =>
      '$_documentsPath/${electionDocumentPath(electionId)}';

  String _ballotPath(String electionId, String userId) =>
      '${_electionDocumentPath(electionId)}/ballots/$userId';

  ProjectsDatabasesDocumentsResource get _documents =>
      _firestore.projects.databases.documents;

  Future<T> _withTransaction<T>(
    FutureOr<T> Function(String) action,
  ) =>
      _documents.withTransaction(action, _databaseId);
}

extension on Document {
  Election toElection() {
    final map = literalValues!;
    return Election(
      id: id,
      name: map['name'] as String,
      candidates: (map['candidates'] as Map<String, dynamic>).keys.toSet(),
      description: map['description'] as String?,
    );
  }

  Ballot toBallot() => Ballot(
        (fields?['rank']?.literal as List? ?? []).cast<String>(),
      );
}

String prettyJson(Object? json) =>
    const JsonEncoder.withIndent(' ').convert(json);
