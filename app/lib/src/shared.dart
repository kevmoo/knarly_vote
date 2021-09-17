const siteTitle = 'Knarly Vote';

Map<String, String> authHeaders(String bearerToken) =>
    {'Authorization': 'Bearer $bearerToken'};

extension ObjectExt on Object {
  void doLog(Object? object) => print('$this : $object');
}
