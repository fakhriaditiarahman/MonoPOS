import 'dart:io';

import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';

class ProductFormState {
  final File? imageFile;
  final String? imageUrl;
  final String? name;
  final int? price;
  final int? wholesalePrice;
  final int? stock;
  final String? unit;
  final String? barcode;
  final String? description;
  final List<ProductUnitEntity> units;
  final Map<int, List<ProductTierEntity>> tieredPrices;
  final List<String> customUnitNames;
  final bool isLoaded;
  final bool isSaving;

  const ProductFormState({
    this.imageFile,
    this.imageUrl,
    this.name,
    this.price,
    this.wholesalePrice,
    this.stock,
    this.unit,
    this.barcode,
    this.description,
    this.units = const [],
    this.tieredPrices = const {},
    this.customUnitNames = const [],
    this.isLoaded = false,
    this.isSaving = false,
  });

  ProductFormState copyWith({
    File? imageFile,
    String? imageUrl,
    String? name,
    int? price,
    int? wholesalePrice,
    int? stock,
    String? unit,
    String? barcode,
    String? description,
    List<ProductUnitEntity>? units,
    Map<int, List<ProductTierEntity>>? tieredPrices,
    List<String>? customUnitNames,
    bool? isLoaded,
    bool? isSaving,
  }) {
    return ProductFormState(
      imageFile: imageFile ?? this.imageFile,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      price: price ?? this.price,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      units: units ?? this.units,
      tieredPrices: tieredPrices ?? this.tieredPrices,
      customUnitNames: customUnitNames ?? this.customUnitNames,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
