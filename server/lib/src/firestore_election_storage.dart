import 'dart:async';
import 'dart:convert';

import 'package:googleapis/cloudtasks/v2.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:knarly_common/knarly_common.dart';

import 'election_storage.dart';
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
  Future<List<ElectionPreview>> listElections(String userId) async {
    final result = await _documents.list(
      _documentsPath,
      rootCollectionName,
    );

    return result.documents!.map((d) => d.toElectionPreview()).toList();
  }

  @override
  FutureOr<Election> getElection(String userId, String electionId) async {
    try {
      final result = await _documents.get(_electionDocumentPath(electionId));

      return result.toElection();
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        throw ServiceException(
          ServiceExceptionKind.resourceNotFound,
          'Election does not exist or user does not have access to it.',
        );
      }
      rethrow;
    }
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

    final ballots = await _withTransaction((p0) async {
      final ballots = <Ballot>[];
      String? nextPageToken;
      do {
        final ballotList = await _documents.list(
          _electionDocumentPath(electionId),
          'ballots',
          pageToken: nextPageToken,
          transaction: p0,
        );
        nextPageToken = ballotList.nextPageToken;
        final documents = ballotList.documents ?? const [];
        ballots.addAll(documents.map((e) => e.toBallot()));
      } while (nextPageToken != null);

      return ballots;
    });

    final condorcetJson = getVoteJson(election, ballots);

    final document = await _documents.patch(
      Document(
        fields: {
          'places': valueFromLiteral(condorcetJson),
          'ballotCount': valueFromLiteral(ballots.length),
        },
      ),
      '$_documentsPath/${electionResultPath(electionId)}',
    );

    print(
      prettyJson({
        'name': document.name,
        'createTime': document.createTime,
        'updateTime': document.updateTime,
      }),
    );
  }

  Future<void> _queElectionUpdateTask(String electionId) async {
    final updateUri = '${config.webHost}/api/elections/$electionId/update';

    if (updateUri.startsWith('https')) {
      final traceParent = currentRequestHeaders!['traceparent'];

      final resultTask = await _tasks.projects.locations.queues.tasks.create(
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
                      'traceparent':
                          TraceContext.parse(traceParent).randomize().toString()
                    },
            ),
          ),
        ),
        'projects/${config.projectId}/locations/${config.electionUpdateTaskLocation}/queues/${config.electionUpdateTaskQueueId}',
      );
      print(prettyJson(resultTask));
    } else {
      final result = await _client.post(Uri.parse(updateUri));
      print(['Did a local update', result.statusCode, result.body].join('\t'));
    }
  }

  void close() {
    _client.close();
  }

  String get _databaseId => 'projects/${config.projectId}/databases/(default)';

  String get _documentsPath => '$_databaseId/documents';

  String _electionDocumentPath(String electionId) =>
      '$_documentsPath/${electionDocumentPath(electionId)}';

  String _ballotPath(String electionId, String userId) =>
      '${_electionDocumentPath(electionId)}/ballots/$userId';

  ProjectsDatabasesDocumentsResource get _documents =>
      _firestore.projects.databases.documents;

  /// Runs [action] within a transaction.
  ///
  /// If [action] succeeds, the transaction is committed.
  /// Otherwise, the transaction in rolled back.
  Future<T> _withTransaction<T>(
    FutureOr<T> Function(String) action,
  ) async {
    final transaction = (await _documents.beginTransaction(
      BeginTransactionRequest(
        options: TransactionOptions(readOnly: ReadOnly()),
      ),
      _databaseId,
    ))
        .transaction!;
    var success = false;
    try {
      final result = await action(transaction);
      success = true;
      return result;
    } finally {
      if (success) {
        await _documents.commit(
          CommitRequest(transaction: transaction),
          _databaseId,
        );
      } else {
        await _documents.rollback(
          RollbackRequest(transaction: transaction),
          _databaseId,
        );
      }
    }
  }
}

Value valueFromLiteral(Object? literal) {
  if (literal is List) {
    return Value(
      arrayValue: ArrayValue(values: literal.map(valueFromLiteral).toList()),
    );
  }

  if (literal is String) {
    return Value(stringValue: literal);
  }

  if (literal is int) {
    return Value(integerValue: literal.toString());
  }

  if (literal is List) {
    return Value(
      arrayValue: ArrayValue(
        values:
            List.generate(literal.length, (i) => valueFromLiteral(literal[i])),
      ),
    );
  }

  if (literal is Map) {
    return Value(
      mapValue: MapValue(
        fields: literal.map(
          (key, value) => MapEntry(key as String, valueFromLiteral(value)),
        ),
      ),
    );
  }

  throw UnimplementedError('For "$literal" - (${literal.runtimeType})');
}

extension ValueExtention on Value {
  Object? get literal {
    if (stringValue != null) {
      return stringValue!;
    }

    if (mapValue != null) {
      return mapValue!.fields!.literalValues;
    }

    if (arrayValue != null) {
      return arrayValue!.values?.map((e) => e.literal).toList() ?? [];
    }

    if (nullValue != null) {
      return null;
    }

    throw UnimplementedError(toJson().toString());
  }
}

extension DocumentExtension on Document {
  String get id => name!.split('/').last;

  ElectionPreview toElectionPreview() {
    final map = fields!.literalValues;
    return ElectionPreview(
      id: id,
      name: map['name'] as String,
    );
  }

  Election toElection() {
    final map = fields!.literalValues;
    return Election(
      id: id,
      name: map['name'] as String,
      candidates: (map['candidates'] as Map<String, dynamic>).keys.toSet(),
    );
  }

  Ballot toBallot() => Ballot(
        (fields?['rank']?.literal as List? ?? []).cast<String>(),
      );
}

extension on Map<String, Value> {
  Map<String, dynamic> get literalValues => Map<String, dynamic>.fromEntries(
        entries.map((e) => MapEntry(e.key, e.value.literal)),
      );
}

String prettyJson(Object? json) =>
    const JsonEncoder.withIndent(' ').convert(json);
