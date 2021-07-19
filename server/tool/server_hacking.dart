import 'package:server/src/firestore_election_storage.dart';
import 'package:server/src/service_config.dart';

Future<void> main() async {
  final storage = await create(ServiceConfig.instance);
  try {
    await storage.updateElection('NL0RpN7Sw6IiO0Z9fICq');
  } finally {
    storage.close();
  }
}
