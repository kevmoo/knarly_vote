import 'dart:async';

import 'package:jose/jose.dart';
import 'package:shelf/shelf.dart';

/// Key used in [Request]`.context` to store the decoded and verified
/// [JsonWebToken] associated with the `authorization` header if it contains
/// a `Bearer` valid token.
const contextKey = 'shelf_jwt_auth';

Middleware addAuthInfo(
  JsonWebKeyStore jsonWebKeyStore, {
  bool ensureVaryOnAuthorizationHeader = false,
  FutureOr<Response?> Function(Request, Object, StackTrace)? onError,
}) =>
    (Handler innerHandler) => (request) async {
          try {
            final jwt = await tokenFromRequest(request, jsonWebKeyStore);
            request = request.change(context: {contextKey: jwt});
          } catch (e, stack) {
            if (onError != null) {
              final possibleResponse = await onError(request, e, stack);
              if (possibleResponse != null) {
                return possibleResponse;
              }
            }
            rethrow;
          }

          var response = await innerHandler(request);

          if (ensureVaryOnAuthorizationHeader) {
            //TODO: need some testing here!
            final varyHeaders = response.headers['vary']
                    ?.split(',')
                    .map((e) => e.trim().toLowerCase())
                    .where((element) => element.isNotEmpty)
                    .toSet() ??
                {};

            if (varyHeaders.add(_authHeader)) {
              response =
                  response.change(headers: {'vary': varyHeaders.join(', ')});
            }
          }

          return response;
        };

FutureOr<JsonWebToken?> tokenFromRequest(
  Request request,
  JsonWebKeyStore store,
) async {
  final auth = request.headers[_authHeader];
  if (auth != null && auth.startsWith(_bearerPrefix)) {
    final jwtString = auth.substring(_bearerPrefix.length);
    return await JsonWebToken.decodeAndVerify(
      jwtString,
      store,
    );
  }
  return null;
}

const _authHeader = 'authorization';
const _bearerPrefix = 'Bearer ';
