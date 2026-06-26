import '../../domain/entities/product_tier_entity.dart';

class ProductTierModel {
  int id;
  int productUnitId;
  int minQty;
  int? maxQty;
  int price;

  ProductTierModel({
    required this.id,
    required this.productUnitId,
    required this.minQty,
    this.maxQty,
    required this.price,
  });

  factory ProductTierModel.fromJson(Map<String, dynamic> json) {
    return ProductTierModel(
      id: json['id'],
      productUnitId: json['productUnitId'],
      minQty: json['minQty'],
      maxQty: json['maxQty'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productUnitId': productUnitId,
      'minQty': minQty,
      'maxQty': maxQty,
      'price': price,
    };
  }

  factory ProductTierModel.fromEntity(ProductTierEntity entity) {
    return ProductTierModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      productUnitId: entity.productUnitId,
      minQty: entity.minQty,
      maxQty: entity.maxQty,
      price: entity.price,
    );
  }

  ProductTierEntity toEntity() {
    return ProductTierEntity(
      id: id,
      productUnitId: productUnitId,
      minQty: minQty,
      maxQty: maxQty,
      price: price,
    );
  }
}
