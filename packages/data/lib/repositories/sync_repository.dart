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
  Future<void> pullAssets() async {
    final isar = await _localDb.db;
    
    // Get last sync time (stored in a separate config or just check latest updated asset?)
    // For simplicity, let's just query everything or use a simple shared_pref for timestamp globally?
    // Let's assume we pass a timestamp or fetch all for now.
    // In a real app, use SharedPreferences to store 'last_asset_sync_time'
    
    try {
      // TODO: Get lastSync from prefs
      String? lastSync = null; 
      final token = await _authRepository.getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await _dio.get(
        '/sync/assets',
        queryParameters: {
          if (lastSync != null) 'lastSync': lastSync,
        },
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
              ..name = data['name']
              ..status = data['status']
              ..location = data['location']
              ..lastScannedAt = data['lastScannedAt'] != null 
                  ? DateTime.parse(data['lastScannedAt']) 
                  : null
              ..lastScannedBy = data['lastScannedBy']
              ..metadataJson = jsonEncode(data['metadata'] ?? {})
              ..updatedAt = DateTime.now(); // Local update time or server time?

            // By default Isar replaces if ID matches, but we used auto-increment ID.
            // We need to query by assetId and update.
            // Or change LocalAsset to use fastHash(assetId) as Id.
            // For now, let's find existing by Index.
            
            final existing = await isar.localAssets
                .filter()
                .assetIdEqualTo(asset.assetId)
                .findFirst();

            if (existing != null) {
              asset.id = existing.id;
            }
            
            await isar.localAssets.put(asset);
          }
        });
      }
    } catch (e) {
      print('Sync Pull Error: $e');
      rethrow;
    }
  }
}
