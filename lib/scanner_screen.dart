import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}
class _ScannerScreenState extends State<ScannerScreen> {
  bool _done = false;
  final _controller = MobileScannerController();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Quét QR / Barcode bằng camera')),
    body: MobileScanner(controller: _controller, onDetect: (capture) {
      if (_done) return;
      for (final code in capture.barcodes) {
        final value = code.rawValue;
        if (value != null && value.isNotEmpty) { _done = true; Navigator.pop(context, value); break; }
      }
    }),
  );
}
