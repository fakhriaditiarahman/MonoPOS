import 'package:equatable/equatable.dart';

class OrderedProductEntity extends Equatable {
  final int? id;
  final int? transactionId;
  final int productId;
  final double quantity;
  final int stock;
  final String name;
  final String imageUrl;
  final int price;
  final String priceType;
  final String unit;
  final int conversionValue;
  final String? createdAt;
  final String? updatedAt;

  const OrderedProductEntity({
    this.id,
    this.transactionId,
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

  OrderedProductEntity copyWith({
    int? id,
    int? transactionId,
    int? productId,
    double? quantity,
    int? stock,
    String? name,
    String? imageUrl,
    int? price,
    String? priceType,
    String? unit,
    int? conversionValue,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderedProductEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      unit: unit ?? this.unit,
      conversionValue: conversionValue ?? this.conversionValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    transactionId,
    productId,
    quantity,
    stock,
    name,
    imageUrl,
    price,
    priceType,
    unit,
    conversionValue,
    createdAt,
    updatedAt,
  ];
}
