import 'package:equatable/equatable.dart';

class ProductUnitEntity extends Equatable {
  final int? id;
  final int productId;
  final String unitName;
  final int conversionValue;
  final int price;
  final int? wholesalePrice;
  final bool isBase;

  const ProductUnitEntity({
    this.id,
    required this.productId,
    required this.unitName,
    required this.conversionValue,
    required this.price,
    this.wholesalePrice,
    this.isBase = false,
  });

  ProductUnitEntity copyWith({
    int? id,
    int? productId,
    String? unitName,
    int? conversionValue,
    int? price,
    int? wholesalePrice,
    bool? isBase,
  }) {
    return ProductUnitEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      unitName: unitName ?? this.unitName,
      conversionValue: conversionValue ?? this.conversionValue,
      price: price ?? this.price,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      isBase: isBase ?? this.isBase,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    unitName,
    conversionValue,
    price,
    wholesalePrice,
    isBase,
  ];
}
