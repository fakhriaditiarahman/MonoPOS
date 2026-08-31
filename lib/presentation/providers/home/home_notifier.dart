import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import '../../widgets/app_low_stock_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../auth/auth_notifier.dart';
import '../payment/payment_notifier.dart';
import '../products/products_notifier.dart';
import 'home_state.dart';

final homeNotifierProvider = NotifierProvider.autoDispose<HomeNotifier, HomeState>(
  HomeNotifier.new,
);

class HomeNotifier extends AutoDisposeNotifier<HomeState> {
  @override
  HomeState build() {
    return const HomeState();
  }

  Future<Result<int>> createTransaction({int lainnyaPrice = 0}) async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) throw 'Unauthenticated!';
      final user = authState.user!;

      final orderedProducts = _buildOrderedList(lainnyaPrice);
      final totalAmount = getTotalAmount() + lainnyaPrice;

      var transaction = TransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: state.selectedPaymentMethod,
        paymentType: state.selectedPaymentType,
        customerId: state.customerId,
        customerName: state.customerName,
        description: state.description,
        orderedProducts: orderedProducts,
        createdById: user.id,
        createdBy: user,
        receivedAmount: state.receivedAmount,
        returnAmount: state.receivedAmount - totalAmount,
        totalOrderedProduct: orderedProducts.length,
        totalAmount: totalAmount,
        paymentStatus: 'paid',
      );

      final transactionRepository = ref.read(transactionRepositoryProvider);
      var res = await CreateTransactionUsecase(transactionRepository).call(transaction);

      if (res.isSuccess) {
        final printResult = await ref.read(printerServiceProvider).printTransaction(transaction);
        if (printResult.isFailure) {
          AppSnackBar.showError('Cetak struk gagal: ${printResult.error}');
        }
      }

      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

      if (res.isSuccess) {
        _checkLowStock(user.id);
      }

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<Result<int>> createQrisTransaction({int lainnyaPrice = 0}) async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) throw 'Unauthenticated!';
      final user = authState.user!;

      final orderedProducts = _buildOrderedList(lainnyaPrice);
      final totalAmount = getTotalAmount() + lainnyaPrice;

      var transaction = TransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: 'qris',
        customerName: state.customerName,
        description: state.description,
        orderedProducts: orderedProducts,
        createdById: user.id,
        createdBy: user,
        receivedAmount: totalAmount,
        returnAmount: 0,
        totalOrderedProduct: orderedProducts.length,
        totalAmount: totalAmount,
        paymentStatus: 'pending',
      );

      final qrisNotifier = ref.read(klikQrisPaymentNotifierProvider.notifier);
      var res = await qrisNotifier.startKlikQrisPayment(
        transaction: transaction,
        totalAmount: totalAmount,
      );

      if (res.isSuccess) {
        ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();
        _checkLowStock(user.id);
      }

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  List<OrderedProductEntity> _buildOrderedList(int lainnyaPrice) {
    final orderedProducts = [...state.orderedProducts];
    if (lainnyaPrice > 0) {
      orderedProducts.add(
        OrderedProductEntity(
          id: DateTime.now().millisecondsSinceEpoch,
          productId: 0,
          quantity: 1,
          stock: 0,
          name: 'Lainnya',
          imageUrl: '',
          price: lainnyaPrice,
          priceType: 'retail',
          unit: 'item',
          conversionValue: 1,
        ),
      );
    }
    return orderedProducts;
  }

  void onChangedIsPanelExpanded(bool val) {
    state = state.copyWith(isPanelExpanded: val);
  }

  Future<void> onAddOrderedProduct(
    ProductEntity product,
    double qty, {
    String? unitName,
    int? conversionValue,
    int? overridePrice,
    String? priceType,
  }) async {
    final orderedProducts = [...state.orderedProducts];
    var currentIndex = orderedProducts.indexWhere((e) => e.productId == product.id);
    final finalPriceType = priceType ?? state.selectedPriceType;
    bool isGrosir = finalPriceType == 'grosir';

    String selectedUnit = unitName ?? product.unit;
    int conversion = conversionValue ?? 1;

    int price = overridePrice ?? (isGrosir && product.wholesalePrice != null ? product.wholesalePrice! : product.price);

    if (overridePrice == null) {
      price = await _resolveTieredPrice(product, selectedUnit, qty, price);
    }

    if (currentIndex != -1) {
      orderedProducts[currentIndex] = orderedProducts[currentIndex].copyWith(
        quantity: qty,
        price: price,
        priceType: finalPriceType,
        unit: selectedUnit,
        conversionValue: conversion,
      );
    } else {
      var order = OrderedProductEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        productId: product.id!,
        quantity: qty,
        stock: product.stock,
        name: product.name,
        imageUrl: product.imageUrl,
        price: price,
        priceType: finalPriceType,
        unit: selectedUnit,
        conversionValue: conversion,
      );

      orderedProducts.add(order);
    }

    state = state.copyWith(orderedProducts: orderedProducts);
  }

  void onChangedPriceType(String value) {
    state = state.copyWith(selectedPriceType: value);
  }

  void onChangedOrderedProductPriceType(int index, String priceType) {
    final orderedProducts = [...state.orderedProducts];
    if (index < 0 || index >= orderedProducts.length) return;

    final item = orderedProducts[index];
    final products = ref.read(berandaProductsNotifierProvider).allProducts;
    final product = products?.where((p) => p.id == item.productId).firstOrNull;

    if (product == null) {
      orderedProducts[index] = item.copyWith(priceType: priceType);
      state = state.copyWith(orderedProducts: orderedProducts);
      return;
    }

    bool isGrosir = priceType == 'grosir';
    int newPrice;

    if (product.units.isNotEmpty) {
      var unit = product.units.firstWhere(
        (u) => u.unitName == item.unit,
        orElse: () => product.units.first,
      );
      newPrice = isGrosir && unit.wholesalePrice != null ? unit.wholesalePrice! : unit.price;
    } else {
      newPrice = isGrosir && product.wholesalePrice != null ? product.wholesalePrice! : product.price;
    }

    orderedProducts[index] = item.copyWith(price: newPrice, priceType: priceType);
    state = state.copyWith(orderedProducts: orderedProducts);
  }

  void onChangedOrderedProductPrice(int index, int newPrice) {
    final orderedProducts = [...state.orderedProducts];
    if (index < 0 || index >= orderedProducts.length) return;

    orderedProducts[index] = orderedProducts[index].copyWith(price: newPrice);
    state = state.copyWith(orderedProducts: orderedProducts);
  }

  void onRemoveOrderedProduct(OrderedProductEntity val) {
    state = state.copyWith(
      orderedProducts: state.orderedProducts.where((e) => e != val).toList(),
    );
  }

  void onRemoveAllOrderedProduct() {
    state = const HomeState();
  }

  Future<void> onChangedOrderedProductQuantity(int index, double value) async {
    final orderedProducts = [...state.orderedProducts];
    final item = orderedProducts[index];
    final products = ref.read(berandaProductsNotifierProvider).allProducts;
    final product = products?.where((p) => p.id == item.productId).firstOrNull;

    int price = item.price;
    if (product != null) {
      price = await _resolveTieredPrice(product, item.unit, value, item.price);
    }

    orderedProducts[index] = item.copyWith(quantity: value, price: price);
    state = state.copyWith(orderedProducts: orderedProducts);
  }

  Future<int> _resolveTieredPrice(ProductEntity product, String unitName, double qty, int fallbackPrice) async {
    try {
      if (product.units.isEmpty) return fallbackPrice;

      var unit = product.units.firstWhere(
        (u) => u.unitName == unitName,
        orElse: () => product.units.first,
      );

      if (unit.id == null || unit.id! <= 0) return fallbackPrice;

      final productRepository = ref.read(productRepositoryProvider);
      final tierRes = await GetProductTiersUsecase(productRepository).call(unit.id!);
      if (!tierRes.isSuccess || tierRes.data == null || tierRes.data!.isEmpty) return fallbackPrice;

      for (final tier in tierRes.data!) {
        final maxQty = tier.maxQty;
        if (maxQty != null) {
          if (qty >= tier.minQty && qty <= maxQty) return tier.price;
        } else {
          if (qty >= tier.minQty) return tier.price;
        }
      }

      return fallbackPrice;
    } catch (_) {
      return fallbackPrice;
    }
  }

  void onChangedReceivedAmount(int value) {
    state = state.copyWith(receivedAmount: value);
  }

  void onChangedPaymentMethod(String? value) {
    state = state.copyWith(selectedPaymentMethod: value ?? state.selectedPaymentMethod);
  }

  void onChangedCustomerName(String value) {
    state = state.copyWith(customerName: value);
  }

  void onChangedCustomerId(String? value) {
    state = state.copyWith(customerId: value);
  }

  void onChangedPaymentType(String value) {
    state = state.copyWith(selectedPaymentType: value);
  }

  void onChangedDescription(String value) {
    state = state.copyWith(description: value);
  }

  int getTotalAmount() {
    if (state.orderedProducts.isEmpty) return 0;
    return state.orderedProducts.map((e) => (e.price * e.quantity).round()).reduce((a, b) => a + b);
  }

  static const int _lowStockThreshold = 5;

  Future<void> _checkLowStock(String userId) async {
    final productRepository = ref.read(productRepositoryProvider);
    final res = await GetLowStockProductsUsecase(productRepository).call((
      userId: userId,
      threshold: _lowStockThreshold,
    ));

    if (res.isSuccess && res.data!.isNotEmpty) {
      AppLowStockDialog.show(res.data!);
    }
  }
}
