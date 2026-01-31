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
              controller.stop();
              _lookupAndShowAssetDialog(context, barcode.rawValue!);
              break;
            }
          }
        },
      ),
    );
  }

  Future<void> _lookupAndShowAssetDialog(BuildContext context, String assetId) async {
    // Try to find asset in local database first
    final localDb = ref.read(localDatabaseProvider);
    final isar = await localDb.db;
    
    final localAsset = await isar.localAssets.getByAssetId(assetId);
    
    if (localAsset != null) {
      // Asset found in local DB - show details
      _showAssetDialog(context, assetId, localAsset);
    } else {
      // Asset not in local DB - show with unknown status
      _showAssetDialog(context, assetId, null);
    }
  }

  void _showAssetDialog(BuildContext context, String assetId, LocalAsset? asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asset ID Header
            Text('Asset Scanned', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(assetId, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Asset Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: asset != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DetailRow(label: 'Name', value: asset.name),
                        _DetailRow(label: 'Status', value: asset.status.toUpperCase(), valueColor: _getStatusColor(asset.status)),
                        _DetailRow(label: 'Location', value: asset.location),
                      ],
                    )
                  : const Column(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                        SizedBox(height: 8),
                        Text('Asset not in local database.', style: TextStyle(color: Colors.orange)),
                        Text('Pull assets from server to sync.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            const Text('Choose Action:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _logEvent(context, assetId, 'SCAN', {}),
              icon: const Icon(Icons.check),
              label: const Text('Log Scan Only'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _logEvent(context, assetId, 'STATUS_CHANGE', {'status': 'maintenance'}),
              icon: const Icon(Icons.build),
              label: const Text('Mark Maintenance'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _logEvent(context, assetId, 'LOCATION_UPDATE', {'location': 'Warehouse B'}),
              icon: const Icon(Icons.warehouse),
              label: const Text('Move to Warehouse B'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
      case 'active':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'retired':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      ..deviceId = 'device_001';

    await isar.writeTxn(() async {
      await isar.localEvents.put(event);
      
      // Also update local asset status if it exists
      if (actionType == 'STATUS_CHANGE' && payload.containsKey('status')) {
        final localAsset = await isar.localAssets.getByAssetId(assetId);
        if (localAsset != null) {
          localAsset.status = payload['status'];
          await isar.localAssets.put(localAsset);
        }
      }
      
      if (actionType == 'LOCATION_UPDATE' && payload.containsKey('location')) {
        final localAsset = await isar.localAssets.getByAssetId(assetId);
        if (localAsset != null) {
          localAsset.location = payload['location'];
          await isar.localAssets.put(localAsset);
        }
      }
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Saved Locally. Remember to Sync!')));
      controller.start();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
