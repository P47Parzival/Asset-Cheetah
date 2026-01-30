import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDialog extends StatelessWidget {
  final String assetId;
  final String assetName;

  const QrCodeDialog({super.key, required this.assetId, required this.assetName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('QR Code: $assetName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: QrImageView(
              data: assetId,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(assetId, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Scan with Mobile App to Track', style: TextStyle(color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ElevatedButton(
          onPressed: () {
            // TODO: Implement Print PDF logic
          },
          child: const Text('Print Label'),
        ),
      ],
    );
  }
}
