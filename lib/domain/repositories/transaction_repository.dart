import '../../core/common/result.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<Result<TransactionEntity?>> getTransaction(int transactionId);

  Future<Result<int>> createTransaction(TransactionEntity transaction);

  Future<Result<void>> updateTransaction(TransactionEntity transaction);

  Future<Result<void>> updatePaymentStatus(
    int transactionId,
    String status, {
    String? paymentQR,
    String? paymentExternalId,
  });

  Future<Result<void>> deleteTransaction(int transactionId);

  Future<Result<List<TransactionEntity>>> getUserTransactions(
    String userId, {
    String orderBy,
    String sortBy,
    int limit,
    int? offset,
    String? contains,
  });

  Future<Result<List<TransactionEntity>>> getTransactionsByDateRange(
    String userId, {
    required String startDate,
    required String endDate,
  });
}
