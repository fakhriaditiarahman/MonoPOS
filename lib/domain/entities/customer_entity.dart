import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String? id;
  final String name;
  final String? phone;
  final String? createdAt;
  final String? updatedAt;

  const CustomerEntity({
    this.id,
    required this.name,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? createdAt,
    String? updatedAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    createdAt,
    updatedAt,
  ];
}
