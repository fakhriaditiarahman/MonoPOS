import 'dart:io';

import '../../../domain/entities/product_unit_entity.dart';

class ProductFormState {
  final File? imageFile;
  final String? imageUrl;
  final String? name;
  final int? price;
  final int? wholesalePrice;
  final int? stock;
  final String unit;
  final String? barcode;
  final String? description;
  final List<ProductUnitEntity> units;
  final bool isLoaded;

  const ProductFormState({
    this.imageFile,
    this.imageUrl,
    this.name,
    this.price,
    this.wholesalePrice,
    this.stock,
    this.unit = 'pcs',
    this.barcode,
    this.description,
    this.units = const [],
    this.isLoaded = false,
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
    bool? isLoaded,
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
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
