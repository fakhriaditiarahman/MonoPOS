import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String? id;
  final String name;
  final String? phone;
  final String type;
  final int creditLimit;
  final int outstandingBalance;
  final String? createdAt;
  final String? updatedAt;

  const CustomerEntity({
    this.id,
    required this.name,
    this.phone,
    this.type = 'retail',
    this.creditLimit = 0,
    this.outstandingBalance = 0,
    this.createdAt,
    this.updatedAt,
  });

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? type,
    int? creditLimit,
    int? outstandingBalance,
    String? createdAt,
    String? updatedAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    type,
    creditLimit,
    outstandingBalance,
    createdAt,
    updatedAt,
  ];
}
