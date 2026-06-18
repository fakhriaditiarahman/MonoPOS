import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';
import 'params/base_params.dart';

class GetUserTransactionsUsecase extends Usecase<Result, BaseParams> {
  GetUserTransactionsUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  @override
  Future<Result<List<TransactionEntity>>> call(BaseParams params) async {
    return _transactionRepository.getUserTransactions(
      params.param,
      orderBy: params.orderBy,
      sortBy: params.sortBy,
      limit: params.limit,
      offset: params.offset,
      contains: params.contains,
    );
  }
}

class GetTransactionUsecase extends Usecase<Result, int> {
  GetTransactionUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  @override
  Future<Result<TransactionEntity?>> call(int params) async => _transactionRepository.getTransaction(params);
}

class CreateTransactionUsecase extends Usecase<Result, TransactionEntity> {
  CreateTransactionUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  @override
  Future<Result<int>> call(TransactionEntity params) async => _transactionRepository.createTransaction(params);
}

class UpateTransactionUsecase extends Usecase<Result<void>, TransactionEntity> {
  UpateTransactionUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  @override
  Future<Result<void>> call(TransactionEntity params) async => _transactionRepository.updateTransaction(params);
}

class DeleteTransactionUsecase extends Usecase<Result<void>, int> {
  DeleteTransactionUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  @override
  Future<Result<void>> call(int params) async => _transactionRepository.deleteTransaction(params);
}

class UpdatePaymentStatusUsecase {
  UpdatePaymentStatusUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  Future<Result<void>> call(int transactionId, String status, {String? paymentQR, String? paymentExternalId}) async {
    return _transactionRepository.updatePaymentStatus(
      transactionId,
      status,
      paymentQR: paymentQR,
      paymentExternalId: paymentExternalId,
    );
  }
}
