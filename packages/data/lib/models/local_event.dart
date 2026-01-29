import 'package:isar/isar.dart';

part 'local_event.g.dart';

@collection
class LocalEvent {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String eventId; // UUID

  @Index()
  late String assetId;

  late String actionType; // 'SCAN', 'STATUS_CHANGE', etc.

  late String payloadJson; // JSON string payload

  late DateTime occurredAt;

  bool isSynced = false;

  late String userId;

  late String deviceId;
}
