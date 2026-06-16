import 'package:equatable/equatable.dart';

import 'product_unit_entity.dart';

class ProductEntity extends Equatable {
  final int? id;
  final String createdById;
  final String name;
  final String imageUrl;
  final int stock;
  final int? sold;
  final int price;
  final int? wholesalePrice;
  final String unit;
  final String? barcode;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final List<ProductUnitEntity> units;

  const ProductEntity({
    this.id,
    required this.createdById,
    required this.name,
    required this.imageUrl,
    required this.stock,
    this.sold,
    required this.price,
    this.wholesalePrice,
    this.unit = 'pcs',
    this.barcode,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.units = const [],
  });

  ProductEntity copyWith({
    int? id,
    String? createdById,
    String? name,
    String? imageUrl,
    int? stock,
    int? sold,
    int? price,
    int? wholesalePrice,
    String? unit,
    String? barcode,
    String? description,
    String? createdAt,
    String? updatedAt,
    List<ProductUnitEntity>? units,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      createdById: createdById ?? this.createdById,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
      price: price ?? this.price,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      units: units ?? this.units,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdById,
    name,
    imageUrl,
    stock,
    sold,
    price,
    wholesalePrice,
    unit,
    barcode,
    description,
    createdAt,
    updatedAt,
    units,
  ];
}
