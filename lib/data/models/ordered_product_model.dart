import '../../domain/entities/ordered_product_entity.dart';

class OrderedProductModel {
  int id;
  int transactionId;
  int productId;
  double quantity;
  int stock;
  String name;
  String imageUrl;
  int price;
  String priceType;
  String unit;
  int conversionValue;
  String? createdAt;
  String? updatedAt;

  OrderedProductModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.stock,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.priceType = 'retail',
    this.unit = 'pcs',
    this.conversionValue = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderedProductModel.fromJson(Map<String, dynamic> json) {
    return OrderedProductModel(
      id: json['id'],
      transactionId: json['transactionId'],
      productId: json['productId'],
      quantity: (json['quantity'] as num).toDouble(),
      stock: json['stock'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      price: json['price'],
      priceType: json['priceType'] ?? 'retail',
      unit: json['unit'] ?? 'pcs',
      conversionValue: json['conversionValue'] ?? 1,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'productId': productId,
      'quantity': quantity,
      'stock': stock,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'priceType': priceType,
      'unit': unit,
      'conversionValue': conversionValue,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory OrderedProductModel.fromEntity(OrderedProductEntity entity) {
    return OrderedProductModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      transactionId: entity.transactionId ?? DateTime.now().millisecondsSinceEpoch,
      productId: entity.productId,
      quantity: entity.quantity,
      stock: entity.stock,
      name: entity.name,
      imageUrl: entity.imageUrl,
      price: entity.price,
      priceType: entity.priceType,
      unit: entity.unit,
      conversionValue: entity.conversionValue,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  OrderedProductEntity toEntity() {
    return OrderedProductEntity(
      id: id,
      transactionId: transactionId,
      productId: productId,
      quantity: quantity,
      stock: stock,
      name: name,
      imageUrl: imageUrl,
      price: price,
      priceType: priceType,
      unit: unit,
      conversionValue: conversionValue,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
