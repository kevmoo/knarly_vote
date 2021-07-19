/// Should evolve to include useful information for logging server-side and,
/// when possible, useful information for the end-user.
class ServiceException implements Exception {
  final ServiceExceptionKind kind;
  final String message;

  ServiceException(this.kind, this.message);

  factory ServiceException.firebaseTokenValidation(String message) =>
      ServiceException(ServiceExceptionKind.firebaseTokenValidation, message);

  int? get clientErrorStatusCode {
    switch (kind) {
      case ServiceExceptionKind.firebaseTokenValidation:
        return 401;
      case ServiceExceptionKind.resourceNotFound:
        return 404;
    }
  }

  @override
  String toString() => 'ServiceException ($kind): $message';
}

enum ServiceExceptionKind {
  /// Issue with the client authorization header - HTTP 401
  firebaseTokenValidation,

  /// Client tried to access an entity that does not exist or that does exist
  /// but the client does not have access to. - HTTP 404
  resourceNotFound,
}
