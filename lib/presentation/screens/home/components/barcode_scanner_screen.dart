import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../domain/usecases/product_usecases.dart';
import '../../../widgets/app_snack_bar.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    _isProcessing = true;

    final repo = ref.read(productRepositoryProvider);
    final result = await GetProductByBarcodeUsecase(repo).call(barcode);

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      Navigator.pop(context, barcode);
    } else {
      _isProcessing = false;
      AppSnackBar.showError('Produk dengan barcode "$barcode" tidak ditemukan');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Arahkan kamera ke barcode produk',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
