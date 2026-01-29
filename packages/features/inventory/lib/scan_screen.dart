import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:data/data.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  final Uuid _uuid = const Uuid();

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              try {
                await ref.read(syncRepositoryProvider).pushEvents();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync successful')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              // Navigate back to login (handled by main.dart usually)
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              controller.stop(); // Stop scanning
              _showAssetDialog(context, barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }

  void _showAssetDialog(BuildContext context, String assetId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Asset Scanned: $assetId', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _logEvent(context, assetId, 'SCAN', {}),
              child: const Text('Log Scan Only'),
            ),
            ElevatedButton(
              onPressed: () => _logEvent(context, assetId, 'STATUS_CHANGE', {'status': 'maintenance'}),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Mark Maintenance'),
            ),
             ElevatedButton(
              onPressed: () => _logEvent(context, assetId, 'LOCATION_UPDATE', {'location': 'Warehouse B'}),
              child: const Text('Move to Warehouse B'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.start();
              },
              child: const Text('Cancel / Scan Next'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logEvent(BuildContext context, String assetId, String actionType, Map<String, dynamic> payload) async {
    final localDb = ref.read(localDatabaseProvider);
    final isar = await localDb.db;
    
    final userId = await ref.read(authRepositoryProvider).getUserId();

    if (userId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in')));
       return;
    }

    final event = LocalEvent()
      ..eventId = _uuid.v4()
      ..assetId = assetId
      ..actionType = actionType
      ..payloadJson = jsonEncode(payload)
      ..occurredAt = DateTime.now()
      ..isSynced = false
      ..userId = userId
      ..deviceId = 'device_001'; // Keep device ID hardcoded or use device_info_plus later

    await isar.writeTxn(() async {
      await isar.localEvents.put(event);
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Saved Locally. Remember to Sync!')));
      controller.start();
    }
  }
}
