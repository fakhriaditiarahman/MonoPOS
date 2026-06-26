import '../../../core/common/result.dart';
import '../../models/receivable_payment_model.dart';

abstract class ReceivablePaymentDatasource {
  Future<Result<int>> createPayment(ReceivablePaymentModel payment);

  Future<Result<List<ReceivablePaymentModel>>> getPaymentsByTransaction(int transactionId);

  Future<Result<List<ReceivablePaymentModel>>> getPaymentsByCustomer(String customerId);
}
