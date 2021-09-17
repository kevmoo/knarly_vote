class NetworkException implements Exception {
  final String message;
  final int statusCode;
  final Uri uri;
  final String? cloudTraceContext;

  NetworkException(
    this.message, {
    required this.statusCode,
    required this.uri,
    this.cloudTraceContext,
  });

  @override
  String toString() => 'NetworkException: $message ($statusCode) $uri';
}
