import '../../../domain/entities/transaction_entity.dart';

class PiutangState {
  final List<TransactionEntity> transactions;
  final bool isLoading;

  const PiutangState({
    this.transactions = const [],
    this.isLoading = false,
  });

  PiutangState copyWith({
    List<TransactionEntity>? transactions,
    bool? isLoading,
  }) {
    return PiutangState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
