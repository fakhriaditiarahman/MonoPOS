import '../../domain/entities/transaction_entity.dart';
import 'ordered_product_model.dart';
import 'user_model.dart';

class TransactionModel {
  int id;
  String paymentMethod;
  String paymentType;
  String? customerId;
  String? customerName;
  String? dueDate;
  String? description;
  String createdById;
  UserModel? createdBy;
  List<OrderedProductModel>? orderedProducts;
  int receivedAmount;
  int returnAmount;
  int totalAmount;
  int totalOrderedProduct;
  String? createdAt;
  String? updatedAt;
  String paymentStatus;
  String? paymentQR;
  String? paymentExternalId;

  TransactionModel({
    required this.id,
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      paymentMethod: json['paymentMethod'],
      paymentType: json['paymentType'] ?? 'cash',
      customerId: json['customerId'],
      customerName: json['customerName'],
      dueDate: json['dueDate'],
      description: json['description'],
      createdById: json['createdById'],
      createdBy: json['createdBy'],
      orderedProducts: json['orderedProducts'] != null
          ? (json['orderedProducts'] as List).map((e) => OrderedProductModel.fromJson(e)).toList()
          : null,
      receivedAmount: json['receivedAmount'],
      returnAmount: json['returnAmount'],
      totalAmount: json['totalAmount'],
      totalOrderedProduct: json['totalOrderedProduct'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      paymentStatus: json['paymentStatus'] ?? 'paid',
      paymentQR: json['paymentQR'],
      paymentExternalId: json['paymentExternalId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentMethod': paymentMethod,
      'paymentType': paymentType,
      'customerId': customerId,
      'customerName': customerName,
      'dueDate': dueDate,
      'description': description,
      'createdById': createdById,
      'createdBy': createdBy,
      'orderedProducts': orderedProducts?.map((e) => e.toJson()).toList(),
      'receivedAmount': receivedAmount,
      'returnAmount': returnAmount,
      'totalAmount': totalAmount,
      'totalOrderedProduct': totalOrderedProduct,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'paymentStatus': paymentStatus,
      'paymentQR': paymentQR,
      'paymentExternalId': paymentExternalId,
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      paymentMethod: entity.paymentMethod,
      paymentType: entity.paymentType,
      customerId: entity.customerId,
      customerName: entity.customerName,
      dueDate: entity.dueDate,
      description: entity.description,
      createdById: entity.createdById,
      createdBy: entity.createdBy != null ? UserModel.fromEntity(entity.createdBy!) : null,
      orderedProducts: entity.orderedProducts?.map((e) => OrderedProductModel.fromEntity(e)).toList(),
      receivedAmount: entity.receivedAmount,
      returnAmount: entity.returnAmount,
      totalAmount: entity.totalAmount,
      totalOrderedProduct: entity.totalOrderedProduct,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
      paymentStatus: entity.paymentStatus,
      paymentQR: entity.paymentQR,
      paymentExternalId: entity.paymentExternalId,
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      paymentMethod: paymentMethod,
      paymentType: paymentType,
      customerId: customerId,
      customerName: customerName,
      dueDate: dueDate,
      description: description,
      createdBy: createdBy?.toEntity(),
      createdById: createdById,
      orderedProducts: orderedProducts?.map((e) => e.toEntity()).toList(),
      receivedAmount: receivedAmount,
      returnAmount: returnAmount,
      totalAmount: totalAmount,
      totalOrderedProduct: totalOrderedProduct,
      createdAt: createdAt,
      updatedAt: updatedAt,
      paymentStatus: paymentStatus,
      paymentQR: paymentQR,
      paymentExternalId: paymentExternalId,
    );
  }
}
