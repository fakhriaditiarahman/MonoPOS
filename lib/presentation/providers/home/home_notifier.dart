import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/customer_usecases.dart';
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

  Future<Result<int>> createTransaction() async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) throw 'Unauthenticated!';
      final user = authState.user!;

      bool isCredit = state.selectedPaymentType == 'credit';

      if (isCredit && state.customerId != null) {
        final customerRepository = ref.read(customerRepositoryProvider);
        final customerRes = await GetCustomerUsecase(customerRepository).call(state.customerId!);
        if (customerRes.isSuccess && customerRes.data != null) {
          final customer = customerRes.data!;
          final newBalance = customer.outstandingBalance + getTotalAmount();
          if (customer.creditLimit > 0 && newBalance > customer.creditLimit) {
            return Result.failure(error: 'Melebihi limit kredit (Rp ${customer.creditLimit})');
          }
        }
      }

      var transaction = TransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: state.selectedPaymentMethod,
        paymentType: state.selectedPaymentType,
        customerId: state.customerId,
        customerName: state.customerName,
        dueDate: isCredit ? state.dueDate : null,
        description: state.description,
        orderedProducts: state.orderedProducts,
        createdById: user.id,
        createdBy: user,
        receivedAmount: isCredit ? 0 : state.receivedAmount,
        returnAmount: isCredit ? 0 : state.receivedAmount - getTotalAmount(),
        totalOrderedProduct: state.orderedProducts.length,
        totalAmount: getTotalAmount(),
        paymentStatus: isCredit ? 'pending' : 'paid',
      );

      final transactionRepository = ref.read(transactionRepositoryProvider);
      var res = await CreateTransactionUsecase(transactionRepository).call(transaction);

      if (res.isSuccess) {
        if (isCredit && state.customerId != null) {
          await _updateCustomerOutstanding(state.customerId!, getTotalAmount());
        }

        final printResult = await ref.read(printerServiceProvider).printTransaction(transaction);
        if (printResult.isFailure) {
          AppSnackBar.showError('Cetak struk gagal: ${printResult.error}');
        }
      }

      ref.read(productsNotifierProvider.notifier).getAllProducts();

      if (res.isSuccess) {
        _checkLowStock(user.id);
      }

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _updateCustomerOutstanding(String customerId, int amount) async {
    final customerRepository = ref.read(customerRepositoryProvider);
    final customerRes = await GetCustomerUsecase(customerRepository).call(customerId);
    if (customerRes.isSuccess && customerRes.data != null) {
      final customer = customerRes.data!;
      await UpdateCustomerUsecase(customerRepository).call(
        customer.copyWith(outstandingBalance: customer.outstandingBalance + amount),
      );
    }
  }

  Future<Result<int>> createQrisTransaction(GoRouter router) async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated) throw 'Unauthenticated!';
      final user = authState.user!;

      var transaction = TransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: 'qris',
        customerName: state.customerName,
        description: state.description,
        orderedProducts: state.orderedProducts,
        createdById: user.id,
        createdBy: user,
        receivedAmount: getTotalAmount(),
        returnAmount: 0,
        totalOrderedProduct: state.orderedProducts.length,
        totalAmount: getTotalAmount(),
        paymentStatus: 'pending',
      );

      final qrisNotifier = ref.read(qrisPaymentNotifierProvider.notifier);
      var res = await qrisNotifier.startQrisPayment(
        transaction: transaction,
        totalAmount: getTotalAmount(),
      );

      if (res.isSuccess) {
        ref.read(productsNotifierProvider.notifier).getAllProducts();
        router.go('/payment/qris');
        _checkLowStock(user.id);
      }

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
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
  }) async {
    final orderedProducts = [...state.orderedProducts];
    var currentIndex = orderedProducts.indexWhere((e) => e.productId == product.id);
    bool isGrosir = state.selectedPriceType == 'grosir';

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

  Future<void> onChangedOrderedProductQuantity(int index, double value) async {
    final orderedProducts = [...state.orderedProducts];
    final item = orderedProducts[index];
    final products = ref.read(productsNotifierProvider).allProducts;
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

  void onChangedDueDate(String value) {
    state = state.copyWith(dueDate: value);
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
