class NetworkException implements Exception {
  final String message;
  final int statusCode;
  final Uri uri;

  NetworkException(this.message, {required this.statusCode, required this.uri});

  @override
  String toString() => 'NetworkException: ($statusCode) $message ($uri)';
}
