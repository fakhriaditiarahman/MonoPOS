import '../../core/common/result.dart';
import '../entities/receivable_payment_entity.dart';

abstract class ReceivablePaymentRepository {
  Future<Result<int>> createPayment(ReceivablePaymentEntity payment);

  Future<Result<List<ReceivablePaymentEntity>>> getPaymentsByTransaction(int transactionId);

  Future<Result<List<ReceivablePaymentEntity>>> getPaymentsByCustomer(String customerId);
}
