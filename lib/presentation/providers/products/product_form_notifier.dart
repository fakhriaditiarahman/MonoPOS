import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';
import '../../../domain/repositories/product_repository.dart';
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

      _ensureDefaultUnitInList(defaultUnit);

      // Load existing tiered prices for each unit
      final units = state.units;
      final tierMap = <int, List<ProductTierEntity>>{};
      for (int i = 0; i < units.length; i++) {
        final unit = units[i];
        if (unit.id != null && unit.id! > 0) {
          final tierRes = await GetProductTiersUsecase(productRepository).call(unit.id!);
          if (tierRes.isSuccess && tierRes.data!.isNotEmpty) {
            tierMap[i] = tierRes.data!;
          }
        }
      }
      if (tierMap.isNotEmpty) {
        state = state.copyWith(tieredPrices: tierMap);
      }
    } else {
      throw res.error ?? 'Failed to load data';
    }
  }

  Future<String?> _saveImageLocally(File source, String subDir, String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/$subDir');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final ext = p.extension(source.path);
      final targetPath = '${targetDir.path}/$fileName$ext';
      await source.copy(targetPath);
      return targetPath;
    } catch (e) {
      cl('Gagal simpan gambar lokal: $e');
      return null;
    }
  }

  Future<Result<int>> createProduct() async {
    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      var imageUrl = state.imageUrl;

      if (state.imageFile != null) {
        final savedPath = await _saveImageLocally(
          state.imageFile!,
          'products',
          '${DateTime.now().millisecondsSinceEpoch}',
        );
        if (savedPath != null) imageUrl = savedPath;
      }

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

      // Save tiered prices for each unit
      if (res.isSuccess) {
        await _saveAllTieredPrices(productRepository);
      }

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
        final savedPath = await _saveImageLocally(
          state.imageFile!,
          'products',
          'product_$id',
        );
        if (savedPath != null) imageUrl = savedPath;
      }

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

      // Save tiered prices for each unit
      if (res.isSuccess) {
        await _saveAllTieredPrices(productRepository);
      }

      ref.read(productsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _saveAllTieredPrices(ProductRepository productRepository) async {
    for (final entry in state.tieredPrices.entries) {
      final unitIndex = entry.key;
      final tiers = entry.value;
      if (tiers.isEmpty) continue;

      final unit = state.units[unitIndex];
      if (unit.id == null || unit.id! <= 0) continue;

      await SaveProductTiersUsecase(productRepository).call((
        productUnitId: unit.id!,
        tiers: tiers,
      ));
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
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(state.tieredPrices);
    tieredPrices.remove(index);
    state = state.copyWith(units: units, tieredPrices: tieredPrices);
  }

  void addTier(int unitIndex, ProductTierEntity tier) {
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(state.tieredPrices);
    final tiers = <ProductTierEntity>[...(tieredPrices[unitIndex] ?? [])];
    tiers.add(tier);
    tieredPrices[unitIndex] = tiers;
    state = state.copyWith(tieredPrices: tieredPrices);
  }

  void updateTier(int unitIndex, int tierIndex, ProductTierEntity tier) {
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(state.tieredPrices);
    final tiers = <ProductTierEntity>[...(tieredPrices[unitIndex] ?? [])];
    if (tierIndex < tiers.length) {
      tiers[tierIndex] = tier;
      tieredPrices[unitIndex] = tiers;
      state = state.copyWith(tieredPrices: tieredPrices);
    }
  }

  void removeTier(int unitIndex, int tierIndex) {
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(state.tieredPrices);
    final tiers = <ProductTierEntity>[...(tieredPrices[unitIndex] ?? [])];
    if (tierIndex < tiers.length) {
      tiers.removeAt(tierIndex);
      tieredPrices[unitIndex] = tiers;
      state = state.copyWith(tieredPrices: tieredPrices);
    }
  }

  List<ProductTierEntity> getTiersForUnit(int unitIndex) {
    return state.tieredPrices[unitIndex] ?? [];
  }
}
