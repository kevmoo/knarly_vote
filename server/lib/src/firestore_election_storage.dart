import 'dart:async';
import 'dart:convert';

import 'package:googleapis/cloudtasks/v2.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:knarly_client/knarly_client.dart';

import 'election_storage.dart';
import 'service_config.dart';
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
  Future<List<Election>> listElection(String userId) async {
    final result = await _documents.list(
      _documentsPath,
      'elections',
    );

    return result.documents!.map((d) => d.toElection()).toList();
  }

  @override
  Future<Ballot> getBallot(String userId, String electionId) async {
    try {
      final document = await _documents.get(
        '$_documentsPath/elections/$electionId/ballots/$userId',
      );

      return document.toBallot();
    } on DetailedApiRequestError catch (e) {
      if (e.jsonResponse?['error']?['code'] == 404) {
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
      await _documents.delete(
        '$_documentsPath/elections/$electionId/ballots/$userId',
      );

      ballot = Ballot([]);
    } else {
      final document = await _documents.patch(
        Document(fields: {'rank': valueFromLiteral(rank)}),
        '$_documentsPath/elections/$electionId/ballots/$userId',
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
      '$_documentsPath/elections/$electionId',
    );

    final election = electionDoc.toElection();

    final ballots = <Ballot>[];

    final transaction = await _documents.beginTransaction(
      BeginTransactionRequest(
        options: TransactionOptions(readOnly: ReadOnly()),
      ),
      _databaseId,
    );
    String? nextPageToken;
    do {
      final ballotList = await _documents.list(
        '$_documentsPath/elections/$electionId',
        'ballots',
        pageToken: nextPageToken,
        transaction: transaction.transaction,
      );
      nextPageToken = ballotList.nextPageToken;
      final documents = ballotList.documents ?? const [];
      ballots.addAll(documents.map((e) => e.toBallot()));
    } while (nextPageToken != null);
    await _documents.commit(
      CommitRequest(transaction: transaction.transaction),
      _databaseId,
    );

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
      final resultTask = await _tasks.projects.locations.queues.tasks.create(
        CreateTaskRequest(
          task: Task(
            httpRequest: HttpRequest(
              url: updateUri,
              oidcToken: OidcToken(
                serviceAccountEmail: config.serviceAccountEmail,
              ),
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

  ProjectsDatabasesDocumentsResource get _documents =>
      _firestore.projects.databases.documents;
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
    throw UnimplementedError(toJson().toString());
  }
}

extension DocumentExtension on Document {
  String get id => name!.split('/').last;

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
