import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/receivable_payment_entity.dart';
import '../repositories/receivable_payment_repository.dart';

class CreateReceivablePaymentUsecase extends Usecase<Result, ReceivablePaymentEntity> {
  CreateReceivablePaymentUsecase(this._repository);

  final ReceivablePaymentRepository _repository;

  @override
  Future<Result<int>> call(ReceivablePaymentEntity params) async {
    return _repository.createPayment(params);
  }
}

class GetPaymentsByTransactionUsecase extends Usecase<Result, int> {
  GetPaymentsByTransactionUsecase(this._repository);

  final ReceivablePaymentRepository _repository;

  @override
  Future<Result<List<ReceivablePaymentEntity>>> call(int params) async {
    return _repository.getPaymentsByTransaction(params);
  }
}
