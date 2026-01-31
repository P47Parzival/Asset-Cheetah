import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:data/data.dart';
import 'package:geolocator/geolocator.dart';
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
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled. Please enable GPS.')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied. Please enable in settings.')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _isLoadingLocation = false);
    } catch (e) {
      print('Location Error: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _refreshLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Location refresh error: $e');
    }
    setState(() => _isLoadingLocation = false);
  }

  String _getLocationString() {
    if (_currentPosition == null) {
      return 'Unknown Location';
    }
    return 'GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}';
  }

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
          // Location indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : IconButton(
                    icon: Icon(
                      _currentPosition != null ? Icons.location_on : Icons.location_off,
                      color: _currentPosition != null ? Colors.green : Colors.red,
                    ),
                    tooltip: _getLocationString(),
                    onPressed: _refreshLocation,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Pull Assets from Server',
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pulling assets from server...')),
                );
                final count = await ref.read(syncRepositoryProvider).pullAssets();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloaded $count assets')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pull failed: $e')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Push Events to Server',
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
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.stop();
                  // Refresh location before showing dialog
                  await _refreshLocation();
                  _lookupAndShowAssetDialog(context, barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Location status banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black87,
              child: Row(
                children: [
                  Icon(
                    _currentPosition != null ? Icons.location_on : Icons.location_off,
                    color: _currentPosition != null ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getLocationString(),
                    style: TextStyle(
                      color: _currentPosition != null ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _lookupAndShowAssetDialog(BuildContext context, String assetId) async {
    final localDb = ref.read(localDatabaseProvider);
    final isar = await localDb.db;
    
    final localAsset = await isar.localAssets.getByAssetId(assetId);
    
    if (localAsset != null) {
      _showAssetDialog(context, assetId, localAsset);
    } else {
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
                        _DetailRow(label: 'Stored Location', value: asset.location),
                        const Divider(),
                        _DetailRow(
                          label: 'Your Location', 
                          value: _getLocationString(),
                          valueColor: _currentPosition != null ? Colors.blue : Colors.grey,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                        const SizedBox(height: 8),
                        const Text('Asset not in local database.', style: TextStyle(color: Colors.orange)),
                        const Text('Pull assets from server to sync.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const Divider(),
                        _DetailRow(
                          label: 'Your Location', 
                          value: _getLocationString(),
                          valueColor: _currentPosition != null ? Colors.blue : Colors.grey,
                        ),
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
              onPressed: () => _logEvent(context, assetId, 'STATUS_CHANGE', {'status': 'in_transit'}),
              icon: const Icon(Icons.warehouse),
              label: const Text('Move to Warehouse B'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
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
      case 'in_transit':
        return Colors.blue;
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

    // Add GPS location to the payload
    final enrichedPayload = Map<String, dynamic>.from(payload);
    if (_currentPosition != null) {
      enrichedPayload['location'] = _getLocationString();
      enrichedPayload['gps'] = {
        'lat': _currentPosition!.latitude,
        'lng': _currentPosition!.longitude,
        'accuracy': _currentPosition!.accuracy,
      };
    }

    final event = LocalEvent()
      ..eventId = _uuid.v4()
      ..assetId = assetId
      ..actionType = actionType
      ..payloadJson = jsonEncode(enrichedPayload)
      ..occurredAt = DateTime.now()
      ..isSynced = false
      ..userId = userId
      ..deviceId = 'device_001';

    await isar.writeTxn(() async {
      await isar.localEvents.put(event);
      
      // Also update local asset status and location if it exists
      final localAsset = await isar.localAssets.getByAssetId(assetId);
      if (localAsset != null) {
        if (actionType == 'STATUS_CHANGE' && payload.containsKey('status')) {
          localAsset.status = payload['status'];
        }
        // Always update location with GPS coordinates
        if (_currentPosition != null) {
          localAsset.location = _getLocationString();
        }
        await isar.localAssets.put(localAsset);
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
          Flexible(
            child: Text(
              value, 
              style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
