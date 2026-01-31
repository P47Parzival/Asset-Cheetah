import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:data/services/local_database.dart';
import 'package:data/models/local_asset.dart';
import 'package:data/models/local_event.dart';
import 'package:data/repositories/auth_repository.dart';
import 'dart:convert';

class SyncRepository {
  final Dio _dio;
  final LocalDatabase _localDb;
  final AuthRepository _authRepository;

  SyncRepository({
    required Dio dio,
    required LocalDatabase localDb,
    required AuthRepository authRepository,
  })  : _dio = dio,
        _localDb = localDb,
        _authRepository = authRepository;

  // Push unsynced events to server
  Future<void> pushEvents() async {
    final isar = await _localDb.db;
    final unsyncedEvents = await isar.localEvents
        .filter()
        .isSyncedEqualTo(false)
        .findAll();

    if (unsyncedEvents.isEmpty) return;

    try {
      // Convert Isar objects to JSON-friendly map for API
      final eventsData = unsyncedEvents.map((e) => {
        'eventId': e.eventId,
        'assetId': e.assetId,
        'actionType': e.actionType,
        'payload': jsonDecode(e.payloadJson),
        'occurredAt': e.occurredAt.toIso8601String(),
        'userId': e.userId,
        'deviceId': e.deviceId,
      }).toList();

      final token = await _authRepository.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.post(
        '/sync/events',
        data: {
          'events': eventsData,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Mark as synced locally
        await isar.writeTxn(() async {
          for (var event in unsyncedEvents) {
            event.isSynced = true;
            await isar.localEvents.put(event);
          }
        });
      }
    } catch (e) {
      print('Sync Push Error: $e');
      rethrow;
    }
  }

  // Pull updated assets from server
  Future<int> pullAssets() async {
    final isar = await _localDb.db;
    int assetCount = 0;
    
    try {
      final token = await _authRepository.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/sync/assets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> assetsData = response.data;
        
        await isar.writeTxn(() async {
          for (var data in assetsData) {
            final asset = LocalAsset()
              ..assetId = data['assetId']
              ..name = data['name'] ?? 'Unknown'
              ..status = data['status'] ?? 'unknown'
              ..location = data['location'] ?? 'Unknown'
              ..lastScannedAt = data['lastScannedAt'] != null 
                  ? DateTime.parse(data['lastScannedAt']) 
                  : null
              ..lastScannedBy = data['lastScannedBy']?.toString()
              ..metadataJson = jsonEncode(data['metadata'] ?? {})
              ..updatedAt = DateTime.now();

            // Use the Isar-generated getByAssetId method
            final existing = await isar.localAssets.getByAssetId(asset.assetId);

            if (existing != null) {
              asset.id = existing.id;
            }
            
            await isar.localAssets.put(asset);
            assetCount++;
          }
        });
      }
      
      return assetCount;
    } catch (e) {
      print('Sync Pull Error: $e');
      rethrow;
    }
  }
}
