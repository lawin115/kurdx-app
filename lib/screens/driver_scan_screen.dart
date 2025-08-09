// lib/screens/driver_scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DriverScanScreen extends StatelessWidget {
  const DriverScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سکانی QR Code بکە')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? qrData = barcodes.first.rawValue;
            if (qrData != null) {
              // پاشگرەکە لادەبەین (بۆ نموونە: "ORDER-ID:123")
              if (qrData.startsWith('ORDER-ID:')) {
                final orderId = qrData.substring(9);
                // گەڕانەوە بۆ لاپەڕەی پێشوو و ناردنی ئایدییەکە
                Navigator.of(context).pop(orderId);
              }
            }
          }
        },
      ),
    );
  }
}