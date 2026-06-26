import 'package:equatable/equatable.dart';

import 'ordered_product_entity.dart';
import 'user_entity.dart';

class TransactionEntity extends Equatable {
  final int? id;
  final String paymentMethod;
  final String paymentType;
  final String? customerId;
  final String? customerName;
  final String? dueDate;
  final String? description;
  final String createdById;
  final UserEntity? createdBy;
  final List<OrderedProductEntity>? orderedProducts;
  final int receivedAmount;
  final int returnAmount;
  final int totalAmount;
  final int totalOrderedProduct;
  final String? createdAt;
  final String? updatedAt;
  final String paymentStatus;
  final String? paymentQR;
  final String? paymentExternalId;

  const TransactionEntity({
    this.id,
    required this.paymentMethod,
    this.paymentType = 'cash',
    this.customerId,
    this.customerName,
    this.dueDate,
    this.description,
    required this.createdById,
    this.createdBy,
    this.orderedProducts,
    required this.receivedAmount,
    required this.returnAmount,
    required this.totalAmount,
    required this.totalOrderedProduct,
    this.createdAt,
    this.updatedAt,
    this.paymentStatus = 'paid',
    this.paymentQR,
    this.paymentExternalId,
  });

  TransactionEntity copyWith({
    int? id,
    String? paymentMethod,
    String? paymentType,
    String? customerId,
    String? customerName,
    String? dueDate,
    String? description,
    String? createdById,
    UserEntity? createdBy,
    List<OrderedProductEntity>? orderdProducts,
    int? receivedAmount,
    int? returnAmount,
    int? totalAmount,
    int? totalOrderedProduct,
    String? createdAt,
    String? updatedAt,
    String? paymentStatus,
    String? paymentQR,
    String? paymentExternalId,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      orderedProducts: orderdProducts ?? orderedProducts,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      returnAmount: returnAmount ?? this.returnAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      totalOrderedProduct: totalOrderedProduct ?? this.totalOrderedProduct,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentQR: paymentQR ?? this.paymentQR,
      paymentExternalId: paymentExternalId ?? this.paymentExternalId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    paymentMethod,
    paymentType,
    customerId,
    customerName,
    dueDate,
    description,
    createdById,
    createdBy,
    orderedProducts,
    receivedAmount,
    returnAmount,
    totalAmount,
    totalOrderedProduct,
    createdAt,
    updatedAt,
    paymentStatus,
    paymentQR,
    paymentExternalId,
  ];
}
