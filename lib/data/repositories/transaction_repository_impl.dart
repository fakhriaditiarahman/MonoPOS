import 'dart:convert';

import '../../../core/common/result.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../../../domain/repositories/transaction_repository.dart';
import '../datasources/interfaces/transaction_datasource.dart';
import '../datasources/local/transaction_local_datasource_impl.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl extends TransactionRepository {
  final TransactionLocalDatasourceImpl transactionLocalDatasource;
  final TransactionDatasource? transactionRemoteDatasource;
  final SyncService syncService;
  final QueuedActionRepository queuedActionRepository;

  TransactionRepositoryImpl({
    required this.transactionLocalDatasource,
    this.transactionRemoteDatasource,
    required this.syncService,
    required this.queuedActionRepository,
  });

  @override
  Future<Result<List<TransactionEntity>>> getUserTransactions(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      var local = await transactionLocalDatasource.getUserTransactions(
        userId,
        orderBy: orderBy,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        contains: contains,
      );

      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<TransactionEntity?>> getTransaction(int transactionId) async {
    try {
      var local = await transactionLocalDatasource.getTransaction(transactionId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<int>> createTransaction(TransactionEntity transaction) async {
    try {
      var data = TransactionModel.fromEntity(transaction);

      var local = await transactionLocalDatasource.createTransaction(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => transactionRemoteDatasource?.createTransaction(data),
        method: 'createTransaction',
        param: data.toJson(),
      );

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updatePaymentStatus(
    int transactionId,
    String status, {
    String? paymentQR,
    String? paymentExternalId,
  }) async {
    try {
      final local = await transactionLocalDatasource.updatePaymentStatus(
        transactionId,
        status,
        paymentQR: paymentQR,
        paymentExternalId: paymentExternalId,
      );
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => transactionRemoteDatasource?.updatePaymentStatus(
          transactionId,
          status,
          paymentQR: paymentQR,
          paymentExternalId: paymentExternalId,
        ),
        method: 'updatePaymentStatus',
        param: {
          'id': transactionId,
          'paymentStatus': status,
          'paymentQR': paymentQR,
          'paymentExternalId': paymentExternalId,
        },
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteTransaction(int transactionId) async {
    try {
      final local = await transactionLocalDatasource.deleteTransaction(transactionId);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => transactionRemoteDatasource?.deleteTransaction(transactionId),
        method: 'deleteTransaction',
        param: {'id': transactionId},
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<TransactionEntity>>> getTransactionsByDateRange(
    String userId, {
    required String startDate,
    required String endDate,
  }) async {
    try {
      var local = await transactionLocalDatasource.getTransactionsByDateRange(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateTransaction(TransactionEntity transaction) async {
    try {
      var data = TransactionModel.fromEntity(transaction);

      final local = await transactionLocalDatasource.updateTransaction(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => transactionRemoteDatasource?.updateTransaction(data),
        method: 'updateTransaction',
        param: data.toJson(),
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _syncRemote({
    required Future<Result<dynamic>>? Function() remoteCall,
    required String method,
    required Map<String, dynamic> param,
  }) async {
    if (transactionRemoteDatasource == null) return;

    if (syncService.isOnline) {
      try {
        final result = await remoteCall();
        if (result?.isSuccess == true) return;
      } catch (_) {}
    }

    await queuedActionRepository.createQueuedAction(
      QueuedActionEntity(
        repository: 'transaction',
        method: method,
        param: jsonEncode(param),
        isCritical: false,
      ),
    );
  }
}
