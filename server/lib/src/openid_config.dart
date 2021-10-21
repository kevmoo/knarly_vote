import 'dart:convert';

import 'package:http/http.dart' as http;

Future<List<Uri>> jwksUris(List<Uri> openIdConfigurationUris) async {
  final client = http.Client();

  Future<Uri> jwksUriFromOpenIdConfig(Uri uri) async {
    try {
      final response = await client.get(uri);

      if (response.statusCode != 200) {
        throw http.ClientException(
          'Status code was ${response.statusCode}',
          uri,
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      final jwks = json['jwks_uri'] as String;

      return Uri.parse(jwks);
    } catch (e, stack) {
      print(['Failing trying to request $uri', e, stack].join('\n'));
      rethrow;
    }
  }

  try {
    final items = <Uri>[];
    for (var configUri in openIdConfigurationUris) {
      items.add(await jwksUriFromOpenIdConfig(configUri));
    }
    return items;
  } finally {
    client.close();
  }
}
