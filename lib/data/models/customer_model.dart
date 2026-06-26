import '../../domain/entities/customer_entity.dart';

class CustomerModel {
  String id;
  String name;
  String? phone;
  String type;
  int creditLimit;
  int outstandingBalance;
  String? createdAt;
  String? updatedAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.type = 'retail',
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      type: json['type'] ?? 'retail',
      creditLimit: json['creditLimit'] ?? 0,
      outstandingBalance: json['outstandingBalance'] ?? 0,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'creditLimit': creditLimit,
      'outstandingBalance': outstandingBalance,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: entity.name,
      phone: entity.phone,
      type: entity.type,
      creditLimit: entity.creditLimit,
      outstandingBalance: entity.outstandingBalance,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  CustomerEntity toEntity() {
    return CustomerEntity(
      id: id,
      name: name,
      phone: phone,
      type: type,
      creditLimit: creditLimit,
      outstandingBalance: outstandingBalance,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
