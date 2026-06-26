import 'package:equatable/equatable.dart';

class ProductTierEntity extends Equatable {
  final int? id;
  final int productUnitId;
  final int minQty;
  final int? maxQty;
  final int price;

  const ProductTierEntity({
    this.id,
    required this.productUnitId,
    required this.minQty,
    this.maxQty,
    required this.price,
  });

  ProductTierEntity copyWith({
    int? id,
    int? productUnitId,
    int? minQty,
    int? maxQty,
    int? price,
  }) {
    return ProductTierEntity(
      id: id ?? this.id,
      productUnitId: productUnitId ?? this.productUnitId,
      minQty: minQty ?? this.minQty,
      maxQty: maxQty ?? this.maxQty,
      price: price ?? this.price,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productUnitId,
    minQty,
    maxQty,
    price,
  ];
}
