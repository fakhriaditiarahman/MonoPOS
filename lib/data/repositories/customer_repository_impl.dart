import 'dart:convert';

import '../../../core/common/result.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/repositories/customer_repository.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../datasources/interfaces/customer_datasource.dart';
import '../datasources/local/customer_local_datasource_impl.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl extends CustomerRepository {
  final CustomerLocalDatasourceImpl customerLocalDatasource;
  final CustomerDatasource? customerRemoteDatasource;
  final SyncService syncService;
  final QueuedActionRepository queuedActionRepository;

  CustomerRepositoryImpl({
    required this.customerLocalDatasource,
    this.customerRemoteDatasource,
    required this.syncService,
    required this.queuedActionRepository,
  });

  @override
  Future<Result<CustomerEntity?>> getCustomer(String id) async {
    try {
      final local = await customerLocalDatasource.getCustomer(id);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> createCustomer(CustomerEntity customer) async {
    try {
      final data = CustomerModel.fromEntity(customer);

      final local = await customerLocalDatasource.createCustomer(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => customerRemoteDatasource?.createCustomer(data),
        method: 'createCustomer',
        param: data.toJson(),
      );

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCustomer(CustomerEntity customer) async {
    try {
      final local = await customerLocalDatasource.updateCustomer(CustomerModel.fromEntity(customer));
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => customerRemoteDatasource?.updateCustomer(CustomerModel.fromEntity(customer)),
        method: 'updateCustomer',
        param: CustomerModel.fromEntity(customer).toJson(),
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCustomer(String id) async {
    try {
      final local = await customerLocalDatasource.deleteCustomer(id);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => customerRemoteDatasource?.deleteCustomer(id),
        method: 'deleteCustomer',
        param: {'id': id},
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<CustomerEntity>>> getAllCustomers() async {
    try {
      final local = await customerLocalDatasource.getAllCustomers();
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<CustomerEntity>>> searchCustomers(String query) async {
    try {
      final local = await customerLocalDatasource.searchCustomers(query);
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
    if (customerRemoteDatasource == null) return;

    if (syncService.isOnline) {
      try {
        final result = await remoteCall();
        if (result?.isSuccess == true) return;
      } catch (_) {}
    }

    await queuedActionRepository.createQueuedAction(
      QueuedActionEntity(
        repository: 'customer',
        method: method,
        param: jsonEncode(param),
        isCritical: false,
      ),
    );
  }
}
