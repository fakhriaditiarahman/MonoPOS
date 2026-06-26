import 'package:equatable/equatable.dart';

class ReceivablePaymentEntity extends Equatable {
  final int? id;
  final int transactionId;
  final String? customerId;
  final int amount;
  final String paymentMethod;
  final String? notes;
  final String? createdAt;

  const ReceivablePaymentEntity({
    this.id,
    required this.transactionId,
    this.customerId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.notes,
    this.createdAt,
  });

  ReceivablePaymentEntity copyWith({
    int? id,
    int? transactionId,
    String? customerId,
    int? amount,
    String? paymentMethod,
    String? notes,
    String? createdAt,
  }) {
    return ReceivablePaymentEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    transactionId,
    customerId,
    amount,
    paymentMethod,
    notes,
    createdAt,
  ];
}
