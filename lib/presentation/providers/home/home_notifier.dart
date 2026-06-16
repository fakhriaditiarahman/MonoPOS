import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import '../auth/auth_notifier.dart';
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

  Future<Result<int>> createTransaction() async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) throw 'Unauthenticated!';
      final user = authState.user!;

      var transaction = TransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: state.selectedPaymentMethod,
        customerName: state.customerName,
        description: state.description,
        orderedProducts: state.orderedProducts,
        createdById: user.id,
        createdBy: user,
        receivedAmount: state.receivedAmount,
        returnAmount: state.receivedAmount - getTotalAmount(),
        totalOrderedProduct: state.orderedProducts.length,
        totalAmount: getTotalAmount(),
      );

      final transactionRepository = ref.read(transactionRepositoryProvider);
      var res = await CreateTransactionUsecase(transactionRepository).call(transaction);

      if (res.isSuccess) {
        // Auto print receipt (fire-and-forget, ignore failure)
        ref.read(printerServiceProvider).printTransaction(transaction);
      }

      // Refresh products
      ref.read(productsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  void onChangedIsPanelExpanded(bool val) {
    state = state.copyWith(isPanelExpanded: val);
  }

  void onAddOrderedProduct(
    ProductEntity product,
    double qty, {
    String? unitName,
    int? conversionValue,
    int? overridePrice,
  }) {
    final orderedProducts = [...state.orderedProducts];
    var currentIndex = orderedProducts.indexWhere((e) => e.productId == product.id);
    bool isGrosir = state.selectedPriceType == 'grosir';

    String selectedUnit = unitName ?? product.unit;
    int conversion = conversionValue ?? 1;

    int price = overridePrice ?? (isGrosir && product.wholesalePrice != null ? product.wholesalePrice! : product.price);

    if (currentIndex != -1) {
      orderedProducts[currentIndex] = orderedProducts[currentIndex].copyWith(
        quantity: qty,
        price: price,
        priceType: state.selectedPriceType,
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
        priceType: state.selectedPriceType,
        unit: selectedUnit,
        conversionValue: conversion,
      );

      orderedProducts.add(order);
    }

    state = state.copyWith(orderedProducts: orderedProducts);
  }

  void onChangedPriceType(String value) {
    final products = ref.read(productsNotifierProvider).allProducts;
    final productMap = {for (var p in products ?? <ProductEntity>[]) p.id: p};

    final orderedProducts = state.orderedProducts.map((item) {
      final product = productMap[item.productId];
      if (product == null) return item.copyWith(priceType: value);

      bool isGrosir = value == 'grosir';

      if (product.units.isNotEmpty) {
        var unit = product.units.firstWhere(
          (u) => u.unitName == item.unit,
          orElse: () => product.units.first,
        );
        int newPrice = isGrosir && unit.wholesalePrice != null ? unit.wholesalePrice! : unit.price;
        return item.copyWith(price: newPrice, priceType: value);
      }

      int newPrice = isGrosir && product.wholesalePrice != null ? product.wholesalePrice! : product.price;
      return item.copyWith(price: newPrice, priceType: value);
    }).toList();

    state = state.copyWith(
      selectedPriceType: value,
      orderedProducts: orderedProducts,
    );
  }

  void onRemoveOrderedProduct(OrderedProductEntity val) {
    state = state.copyWith(
      orderedProducts: state.orderedProducts.where((e) => e != val).toList(),
    );
  }

  void onRemoveAllOrderedProduct() {
    state = const HomeState();
  }

  void onChangedOrderedProductQuantity(int index, double value) {
    final orderedProducts = [...state.orderedProducts];
    orderedProducts[index] = orderedProducts[index].copyWith(quantity: value);
    state = state.copyWith(orderedProducts: orderedProducts);
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

  void onChangedDescription(String value) {
    state = state.copyWith(description: value);
  }

  int getTotalAmount() {
    if (state.orderedProducts.isEmpty) return 0;
    return state.orderedProducts.map((e) => (e.price * e.quantity).round()).reduce((a, b) => a + b);
  }
}
