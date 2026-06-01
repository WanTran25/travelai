import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> get dbPath async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'travelai_database.db');
}

DatabaseFactory get databaseFactory => databaseFactoryIo;
