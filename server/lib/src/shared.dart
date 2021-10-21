import 'package:shelf/shelf.dart';

void debugPrintRequestHeaders(Request request) {
  print(
    '''
***REQUEST HEADERS***
${prettyMap(request.headers)}
***END REQUEST HEADERS***''',
  );
}

String prettyMap(Map<String, dynamic> input) =>
    (input.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
        .map((e) => '${e.key.padRight(30)} ${e.value}')
        .join('\n');
