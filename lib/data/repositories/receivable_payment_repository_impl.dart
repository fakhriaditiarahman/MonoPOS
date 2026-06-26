import 'dart:convert';

import '../../../core/common/result.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/entities/receivable_payment_entity.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../../../domain/repositories/receivable_payment_repository.dart';
import '../datasources/interfaces/receivable_payment_datasource.dart';
import '../datasources/local/receivable_payment_local_datasource_impl.dart';
import '../models/receivable_payment_model.dart';

class ReceivablePaymentRepositoryImpl extends ReceivablePaymentRepository {
  final ReceivablePaymentLocalDatasourceImpl localDatasource;
  final ReceivablePaymentDatasource? remoteDatasource;
  final SyncService syncService;
  final QueuedActionRepository queuedActionRepository;

  ReceivablePaymentRepositoryImpl({
    required this.localDatasource,
    this.remoteDatasource,
    required this.syncService,
    required this.queuedActionRepository,
  });

  @override
  Future<Result<int>> createPayment(ReceivablePaymentEntity payment) async {
    try {
      final data = ReceivablePaymentModel.fromEntity(payment);

      final local = await localDatasource.createPayment(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => remoteDatasource?.createPayment(data),
        method: 'createPayment',
        param: data.toJson(),
      );

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ReceivablePaymentEntity>>> getPaymentsByTransaction(int transactionId) async {
    try {
      final local = await localDatasource.getPaymentsByTransaction(transactionId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ReceivablePaymentEntity>>> getPaymentsByCustomer(String customerId) async {
    try {
      final local = await localDatasource.getPaymentsByCustomer(customerId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _syncRemote({
    required Future<Result<dynamic>>? Function() remoteCall,
    required String method,
    required Map<String, dynamic> param,
  }) async {
    if (remoteDatasource == null) return;

    if (syncService.isOnline) {
      try {
        final result = await remoteCall();
        if (result?.isSuccess == true) return;
      } catch (_) {}
    }

    await queuedActionRepository.createQueuedAction(
      QueuedActionEntity(
        repository: 'receivable_payment',
        method: method,
        param: jsonEncode(param),
        isCritical: false,
      ),
    );
  }
}
