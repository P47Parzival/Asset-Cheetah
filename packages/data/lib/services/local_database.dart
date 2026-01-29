import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:data/models/local_asset.dart';
import 'package:data/models/local_event.dart';

class LocalDatabase {
  late Future<Isar> db;

  LocalDatabase() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [LocalAssetSchema, LocalEventSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
