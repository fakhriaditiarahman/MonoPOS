import '../../../domain/entities/receivable_payment_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

class PiutangDetailState {
  final TransactionEntity? transaction;
  final List<ReceivablePaymentEntity> payments;
  final bool isLoading;

  const PiutangDetailState({
    this.transaction,
    this.payments = const [],
    this.isLoading = false,
  });

  PiutangDetailState copyWith({
    TransactionEntity? transaction,
    List<ReceivablePaymentEntity>? payments,
    bool? isLoading,
  }) {
    return PiutangDetailState(
      transaction: transaction ?? this.transaction,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
