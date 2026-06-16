import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../auth/auth_notifier.dart';
import 'product_form_state.dart';
import 'products_notifier.dart';

final productFormNotifierProvider = NotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>(
  ProductFormNotifier.new,
);

class ProductFormNotifier extends AutoDisposeNotifier<ProductFormState> {
  @override
  ProductFormState build() {
    return const ProductFormState();
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  int _unitIdCounter = 0;

  Future<void> initProductForm(int? productId) async {
    if (productId == null) {
      state = state.copyWith(isLoaded: true);
      // Ensure default unit 'pcs' exists in new product
      _ensureDefaultUnitInList('pcs');
      return;
    }

    final productRepository = ref.read(productRepositoryProvider);
    var res = await GetProductUsecase(productRepository).call(productId);

    if (res.isSuccess) {
      var product = res.data;
      final defaultUnit = product?.unit ?? 'pcs';

      state = state.copyWith(
        imageUrl: product?.imageUrl,
        name: product?.name,
        price: product?.price,
        wholesalePrice: product?.wholesalePrice,
        stock: product?.stock,
        unit: defaultUnit,
        barcode: product?.barcode,
        description: product?.description,
        units: product?.units ?? [],
        isLoaded: true,
      );

      // Ensure default unit is in the units list
      _ensureDefaultUnitInList(defaultUnit);
    } else {
      throw res.error ?? 'Failed to load data';
    }
  }

  Future<Result<int>> createProduct() async {
    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      var imageUrl = state.imageUrl;

      if (state.imageFile != null) {
        imageUrl = state.imageFile!.path;
      }

      cl('imageUrl $imageUrl');

      var product = ProductEntity(
        createdById: userId,
        name: state.name ?? '',
        imageUrl: imageUrl ?? '',
        stock: state.stock ?? 0,
        price: state.price ?? 0,
        wholesalePrice: state.wholesalePrice,
        unit: state.unit,
        barcode: state.barcode,
        description: state.description ?? '',
        units: state.units,
      );

      var res = await CreateProductUsecase(productRepository).call(product);

      // Refresh products
      ref.read(productsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<Result<void>> updatedProduct(int id) async {
    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      var imageUrl = state.imageUrl;

      if (state.imageFile != null) {
        imageUrl = state.imageFile!.path;
      }

      cl('imageUrl $imageUrl');

      var product = ProductEntity(
        id: id,
        createdById: userId,
        name: state.name!,
        imageUrl: imageUrl ?? '',
        stock: state.stock ?? 0,
        price: state.price ?? 0,
        wholesalePrice: state.wholesalePrice,
        unit: state.unit,
        barcode: state.barcode,
        description: state.description ?? '',
        units: state.units,
      );

      var res = await UpdateProductUsecase(productRepository).call(product);

      // Refresh products
      ref.read(productsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<Result<void>> deleteProduct(int id) async {
    try {
      final productRepository = ref.read(productRepositoryProvider);
      var res = await DeleteProductUsecase(productRepository).call(id);

      // Refresh products
      ref.read(productsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  void onChangedImage(File value) {
    state = state.copyWith(imageFile: value);
  }

  void onChangedName(String value) {
    state = state.copyWith(name: value);
  }

  void onChangedPrice(String value) {
    state = state.copyWith(price: int.tryParse(value));
  }

  void onChangedWholesalePrice(String value) {
    state = state.copyWith(wholesalePrice: int.tryParse(value));
  }

  void onChangedStock(String value) {
    state = state.copyWith(stock: int.tryParse(value));
  }

  void onChangedUnit(String value) {
    state = state.copyWith(unit: value);
    _ensureDefaultUnitInList(value);
  }

  void _ensureDefaultUnitInList(String defaultUnit) {
    // Ensure default unit exists in units list
    final units = [...state.units];
    final unitExists = units.any((u) => u.unitName == defaultUnit);

    if (!unitExists) {
      // Create default unit with 0 price initially (user must fill in)
      final defaultUnitEntity = ProductUnitEntity(
        unitName: defaultUnit,
        conversionValue: 1,
        price: state.price ?? 0, // Use current price
        wholesalePrice: state.wholesalePrice,
        isBase: true,
        productId: 0,
      );
      units.add(defaultUnitEntity);
      state = state.copyWith(units: units);
    }
  }

  void onChangedBarcode(String value) {
    state = state.copyWith(barcode: value.isEmpty ? null : value);
  }

  void onChangedDesc(String value) {
    state = state.copyWith(description: value);
  }

  void addUnit(ProductUnitEntity unit) {
    final units = [...state.units];
    final newUnit = unit.copyWith(id: _unitIdCounter--);
    units.add(newUnit);
    state = state.copyWith(units: units);
  }

  void updateUnit(int index, ProductUnitEntity unit) {
    final units = [...state.units];
    units[index] = unit;
    state = state.copyWith(units: units);
  }

  void removeUnit(int index) {
    final units = [...state.units];
    units.removeAt(index);
    state = state.copyWith(units: units);
  }
}
