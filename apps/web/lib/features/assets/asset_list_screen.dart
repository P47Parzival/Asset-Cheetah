import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data/web_providers.dart';
import 'package:data/repositories/dashboard_repository.dart';

import 'add_asset_dialog.dart';
import 'qr_code_dialog.dart';

class AssetListScreen extends ConsumerStatefulWidget {
  const AssetListScreen({super.key});

  @override
  ConsumerState<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends ConsumerState<AssetListScreen> {
  List<dynamic> _assets = [];
  int _page = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    setState(() => _isLoading = true);
    try {
      final data = await ref.read(dashboardRepositoryProvider).getAssets(page: _page);
      if (mounted) {
        setState(() {
          _assets = data['assets'];
          _totalPages = data['pages'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _nextPage() {
    if (_page < _totalPages) {
      setState(() => _page++);
      _fetchAssets();
    }
  }

  void _prevPage() {
    if (_page > 1) {
      setState(() => _page--);
      _fetchAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _assets.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddAssetDialog(onAssetAdded: _fetchAssets),
          );
        },
        label: const Text('Add Asset'),
        icon: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asset Inventory', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Asset ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Location')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: _assets.map((asset) {
                      return DataRow(
                        cells: [
                          DataCell(Text(asset['assetId'] ?? '-')),
                          DataCell(Text(asset['name'] ?? '-')),
                          DataCell(_StatusBadge(status: asset['status'])),
                          DataCell(Text(asset['location'] ?? '-')),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.qr_code),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => QrCodeDialog(
                                    assetId: asset['assetId'],
                                    assetName: asset['name'],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: _page > 1 ? _prevPage : null, icon: const Icon(Icons.chevron_left)),
                Text('Page $_page of $_totalPages'),
                IconButton(onPressed: _page < _totalPages ? _nextPage : null, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'active') color = Colors.green;
    if (status == 'operational') color = Colors.green; // Handle operational as well
    if (status == 'maintenance') color = Colors.orange;
    if (status == 'retired') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(status?.toUpperCase() ?? 'UNKNOWN', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
