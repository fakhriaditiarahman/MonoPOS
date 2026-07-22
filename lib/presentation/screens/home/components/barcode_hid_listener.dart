import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../domain/usecases/product_usecases.dart';
import '../../../providers/home/home_notifier.dart';
import '../../../providers/products/products_notifier.dart';
import '../../../widgets/app_snack_bar.dart';

class BarcodeHidListener extends ConsumerStatefulWidget {
  const BarcodeHidListener({super.key});

  @override
  ConsumerState<BarcodeHidListener> createState() => _BarcodeHidListenerState();
}

class _BarcodeHidListenerState extends ConsumerState<BarcodeHidListener> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSubmitted(String value) async {
    final trimmed = value.trim();
    _controller.clear();

    if (trimmed.isEmpty || _isProcessing) return;

    _isProcessing = true;

    final products = ref.read(productsNotifierProvider).allProducts;
    final product = products?.where((p) => p.barcode == trimmed).firstOrNull;

    if (product == null) {
      final repo = ref.read(productRepositoryProvider);
      final result = await GetProductByBarcodeUsecase(repo).call(trimmed);

      if (result.isSuccess && result.data != null) {
        if (mounted) {
          await ref.read(productsNotifierProvider.notifier).getAllProducts();
        }
        final refreshedProducts = ref.read(productsNotifierProvider).allProducts;
        final foundProduct = refreshedProducts?.where((p) => p.id == result.data!.id).firstOrNull;

        if (foundProduct != null && mounted) {
          _addToCart(foundProduct);
        } else if (mounted) {
          _onProductNotFound(trimmed);
        }
      } else if (mounted) {
        _onProductNotFound(trimmed);
      }
    } else {
      _addToCart(product);
    }

    _isProcessing = false;
    _focusNode.requestFocus();
  }

  void _addToCart(product) {
    final homeState = ref.read(homeNotifierProvider);
    final currentQty = homeState.orderedProducts.where((e) => e.productId == product.id).firstOrNull?.quantity ?? 0;

    ref
        .read(homeNotifierProvider.notifier)
        .onAddOrderedProduct(
          product,
          currentQty + 1,
          unitName: product.unit,
          conversionValue: 1,
        );

    SystemSound.play(SystemSoundType.click);

    if (mounted) {
      final totalQty = (currentQty + 1).toInt();
      AppSnackBar.show('${product.name} ($totalQty)');
    }
  }

  void _onProductNotFound(String barcode) {
    AppSnackBar.showError('Produk "$barcode" tidak ditemukan');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: 0,
      child: TextField(
        autofocus: true,
        focusNode: _focusNode,
        controller: _controller,
        onSubmitted: _onSubmitted,
        showCursor: false,
        decoration: const InputDecoration.collapsed(hintText: ''),
      ),
    );
  }
}
