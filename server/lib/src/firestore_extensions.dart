import 'dart:async';

import 'package:googleapis/firestore/v1.dart';

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
      return mapValue!.fields!
          .map((key, value) => MapEntry(key, value.literal));
    }

    if (arrayValue != null) {
      return arrayValue!.values?.map((e) => e.literal).toList() ?? [];
    }

    if (nullValue != null) {
      return null;
    }

    if (integerValue != null) {
      return int.parse(integerValue!);
    }

    throw UnimplementedError(toJson().toString());
  }
}

extension DocumentExtension on Document {
  String get id => name!.split('/').last;

  Map<String, dynamic>? get literalValues =>
      fields?.map((key, value) => MapEntry(key, value.literal));
}

extension ProjectsDatabasesDocumentsResourceExtension
    on ProjectsDatabasesDocumentsResource {
  Future<Document?> getOrNull(
    String name, {
    // ignore: non_constant_identifier_names
    List<String>? mask_fieldPaths,
    String? readTime,
    String? transaction,
    String? $fields,
  }) async {
    try {
      final value = await get(
        name,
        mask_fieldPaths: mask_fieldPaths,
        readTime: readTime,
        transaction: transaction,
        $fields: $fields,
      );
      return value;
    } on DetailedApiRequestError catch (e) {
      if (e.status == 404) {
        return null;
      }
      rethrow;
    }
  }

  Stream<List<Document>> listAll(
    String parent,
    String collectionId, {
    int? pageSize,
    String? transaction,
  }) async* {
    String? nextPageToken;
    do {
      final result = await list(
        parent,
        collectionId,
        pageSize: pageSize,
        pageToken: nextPageToken,
        transaction: transaction,
      );
      nextPageToken = result.nextPageToken;
      yield result.documents!;
    } while (nextPageToken != null);
  }

  /// Runs [action] within a transaction.
  ///
  /// If [action] succeeds, the transaction is committed.
  /// Otherwise, the transaction in rolled back.
  Future<T> withTransaction<T>(
    FutureOr<T> Function(String) action,
    String database,
  ) async {
    final transaction = (await beginTransaction(
      BeginTransactionRequest(
        options: TransactionOptions(readOnly: ReadOnly()),
      ),
      database,
    ))
        .transaction!;
    var success = false;
    try {
      final result = await action(transaction);
      success = true;
      return result;
    } finally {
      if (success) {
        await commit(
          CommitRequest(transaction: transaction),
          database,
        );
      } else {
        await rollback(
          RollbackRequest(transaction: transaction),
          database,
        );
      }
    }
  }
}
