import '../../domain/entities/product_unit_entity.dart';

class ProductUnitModel {
  int id;
  int productId;
  String unitName;
  int conversionValue;
  int price;
  int? wholesalePrice;
  bool isBase;

  ProductUnitModel({
    required this.id,
    required this.productId,
    required this.unitName,
    required this.conversionValue,
    required this.price,
    this.wholesalePrice,
    this.isBase = false,
  });

  factory ProductUnitModel.fromJson(Map<String, dynamic> json) {
    return ProductUnitModel(
      id: json['id'],
      productId: json['productId'],
      unitName: json['unitName'],
      conversionValue: json['conversionValue'],
      price: json['price'],
      wholesalePrice: json['wholesalePrice'],
      isBase: json['isBase'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'unitName': unitName,
      'conversionValue': conversionValue,
      'price': price,
      'wholesalePrice': wholesalePrice,
      'isBase': isBase ? 1 : 0,
    };
  }

  factory ProductUnitModel.fromEntity(ProductUnitEntity entity) {
    return ProductUnitModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      productId: entity.productId,
      unitName: entity.unitName,
      conversionValue: entity.conversionValue,
      price: entity.price,
      wholesalePrice: entity.wholesalePrice,
      isBase: entity.isBase,
    );
  }

  ProductUnitEntity toEntity() {
    return ProductUnitEntity(
      id: id,
      productId: productId,
      unitName: unitName,
      conversionValue: conversionValue,
      price: price,
      wholesalePrice: wholesalePrice,
      isBase: isBase,
    );
  }
}
