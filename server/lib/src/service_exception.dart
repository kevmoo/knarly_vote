/// Should evolve to include useful information for logging server-side and,
/// when possible, useful information for the end-user.
class ServiceException implements Exception {
  final ServiceExceptionKind kind;
  final String message;

  final Object? innerError;
  final StackTrace? innerStack;

  ServiceException(
    this.kind,
    this.message, {
    this.innerError,
    this.innerStack,
  });

  factory ServiceException.authorizationTokenValidation(String message) =>
      ServiceException(
        ServiceExceptionKind.authorizationTokenValidation,
        message,
      );

  int? get clientErrorStatusCode {
    switch (kind) {
      case ServiceExceptionKind.badUpdateRequest:
        return 400;
      case ServiceExceptionKind.authorizationTokenValidation:
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
  authorizationTokenValidation,

  /// Client tried to access an entity that does not exist or that does exist
  /// but the client does not have access to. - HTTP 404
  resourceNotFound,

  /// Received a bad request on an update endpoint that should be accessed via
  /// pub-sub.
  badUpdateRequest,
}
