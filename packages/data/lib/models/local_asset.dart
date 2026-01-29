import 'package:isar/isar.dart';

part 'local_asset.g.dart';

@collection
class LocalAsset {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String assetId;

  late String name;

  @Index()
  late String status; // 'operational', 'maintenance', 'retired', 'in_transit'

  late String location;

  DateTime? lastScannedAt;

  String? lastScannedBy; // Stores the User ID locally as a string

  late String metadataJson; // Store Map<String,String> as JSON string for Isar

  DateTime? updatedAt;
}
