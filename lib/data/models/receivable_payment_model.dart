import '../../domain/entities/receivable_payment_entity.dart';

class ReceivablePaymentModel {
  int id;
  int transactionId;
  String? customerId;
  int amount;
  String paymentMethod;
  String? notes;
  String? createdAt;

  ReceivablePaymentModel({
    required this.id,
    required this.transactionId,
    this.customerId,
    required this.amount,
    this.paymentMethod = 'cash',
    this.notes,
    this.createdAt,
  });

  factory ReceivablePaymentModel.fromJson(Map<String, dynamic> json) {
    return ReceivablePaymentModel(
      id: json['id'],
      transactionId: json['transactionId'],
      customerId: json['customerId'],
      amount: json['amount'],
      paymentMethod: json['paymentMethod'] ?? 'cash',
      notes: json['notes'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'customerId': customerId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory ReceivablePaymentModel.fromEntity(ReceivablePaymentEntity entity) {
    return ReceivablePaymentModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      transactionId: entity.transactionId,
      customerId: entity.customerId,
      amount: entity.amount,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  ReceivablePaymentEntity toEntity() {
    return ReceivablePaymentEntity(
      id: id,
      transactionId: transactionId,
      customerId: customerId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
