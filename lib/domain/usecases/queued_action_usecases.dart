import 'dart:convert';

import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../../data/datasources/interfaces/product_datasource.dart';
import '../../data/datasources/interfaces/transaction_datasource.dart';
import '../../data/datasources/interfaces/user_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/user_model.dart';
import '../entities/queued_action_entity.dart';
import '../repositories/queued_action_repository.dart';
import 'params/no_param.dart';

class CreateQueuedActionUsecase extends Usecase<Result<int>, QueuedActionEntity> {
  CreateQueuedActionUsecase(this._repository);

  final QueuedActionRepository _repository;

  @override
  Future<Result<int>> call(QueuedActionEntity params) async => _repository.createQueuedAction(params);
}

class GetAllQueuedActionsUsecase extends Usecase<Result<List<QueuedActionEntity>>, NoParam> {
  GetAllQueuedActionsUsecase(this._repository);

  final QueuedActionRepository _repository;

  @override
  Future<Result<List<QueuedActionEntity>>> call(NoParam params) async => _repository.getAllQueuedActions();
}

class DeleteQueuedActionUsecase extends Usecase<Result<void>, int> {
  DeleteQueuedActionUsecase(this._repository);

  final QueuedActionRepository _repository;

  @override
  Future<Result<void>> call(int params) async => _repository.deleteQueuedAction(params);
}

class ProcessQueuedActionUsecase extends Usecase<Result<void>, QueuedActionEntity> {
  final QueuedActionRepository _queuedActionRepository;
  final ProductDatasource? _productRemote;
  final UserDatasource? _userRemote;
  final TransactionDatasource? _transactionRemote;

  ProcessQueuedActionUsecase(
    this._queuedActionRepository, {
    ProductDatasource? productRemote,
    UserDatasource? userRemote,
    TransactionDatasource? transactionRemote,
  }) : _productRemote = productRemote,
       _userRemote = userRemote,
       _transactionRemote = transactionRemote;

  @override
  Future<Result<void>> call(QueuedActionEntity params) async {
    try {
      Map<String, dynamic> param;
      try {
        param = jsonDecode(params.param) as Map<String, dynamic>;
      } catch (_) {
        await _queuedActionRepository.deleteQueuedAction(params.id!);
        return Result.failure(error: 'Invalid param JSON');
      }

      Result<dynamic>? result;

      switch ('${params.repository}/${params.method}') {
        case 'user/createUser':
          result = await _userRemote?.createUser(UserModel.fromJson(param));
        case 'user/updateUser':
          result = await _userRemote?.updateUser(UserModel.fromJson(param));
        case 'user/deleteUser':
          result = await _userRemote?.deleteUser(param['id'] as String);
        case 'product/createProduct':
          result = await _productRemote?.createProduct(ProductModel.fromJson(param));
        case 'product/updateProduct':
          result = await _productRemote?.updateProduct(ProductModel.fromJson(param));
        case 'product/deleteProduct':
          result = await _productRemote?.deleteProduct(param['id'] as int);
        case 'product/saveProductUnits':
          // Not re-queued; handled inline by the create/update product flow
          result = Result.success(data: null);
        case 'transaction/createTransaction':
          result = await _transactionRemote?.createTransaction(TransactionModel.fromJson(param));
        case 'transaction/updateTransaction':
          result = await _transactionRemote?.updateTransaction(TransactionModel.fromJson(param));
        case 'transaction/updatePaymentStatus':
          result = await _transactionRemote?.updatePaymentStatus(
            param['id'] as int,
            param['paymentStatus'] as String,
            paymentQR: param['paymentQR'] as String?,
            paymentExternalId: param['paymentExternalId'] as String?,
          );
        case 'transaction/deleteTransaction':
          result = await _transactionRemote?.deleteTransaction(param['id'] as int);
        default:
          await _queuedActionRepository.deleteQueuedAction(params.id!);
          return Result.failure(error: 'Unknown action: ${params.repository}/${params.method}');
      }

      if (result != null && result.isSuccess) {
        await _queuedActionRepository.deleteQueuedAction(params.id!);
        return Result.success(data: null);
      }

      return Result.failure(error: result?.error ?? 'Sync failed');
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
