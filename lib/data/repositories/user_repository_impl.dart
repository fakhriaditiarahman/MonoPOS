import 'dart:convert';

import '../../../core/common/result.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../datasources/interfaces/user_datasource.dart';
import '../datasources/local/user_local_datasource_impl.dart';
import '../models/user_model.dart';

class UserRepositoryImpl extends UserRepository {
  final UserLocalDatasourceImpl userLocalDatasource;
  final UserDatasource? userRemoteDatasource;
  final SyncService syncService;
  final QueuedActionRepository queuedActionRepository;

  UserRepositoryImpl({
    required this.userLocalDatasource,
    this.userRemoteDatasource,
    required this.syncService,
    required this.queuedActionRepository,
  });

  @override
  Future<Result<UserEntity?>> getUser(String userId) async {
    try {
      var local = await userLocalDatasource.getUser(userId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> createUser(UserEntity user) async {
    try {
      var local = await userLocalDatasource.createUser(UserModel.fromEntity(user));
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => userRemoteDatasource?.createUser(UserModel.fromEntity(user)),
        method: 'createUser',
        param: UserModel.fromEntity(user).toJson(),
      );

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteUser(String userId) async {
    try {
      final local = await userLocalDatasource.deleteUser(userId);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => userRemoteDatasource?.deleteUser(userId),
        method: 'deleteUser',
        param: {'id': userId},
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateUser(UserEntity user) async {
    try {
      final local = await userLocalDatasource.updateUser(UserModel.fromEntity(user));
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => userRemoteDatasource?.updateUser(UserModel.fromEntity(user)),
        method: 'updateUser',
        param: UserModel.fromEntity(user).toJson(),
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserEntity?>> getUserByUsername(String username) async {
    try {
      var local = await userLocalDatasource.getUserByUsername(username);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<UserEntity>>> getAllUsers() async {
    try {
      var local = await userLocalDatasource.getAllUsers();
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
    if (userRemoteDatasource == null) return;

    if (syncService.isOnline) {
      try {
        final result = await remoteCall();
        if (result?.isSuccess == true) return;
      } catch (_) {}
    }

    await queuedActionRepository.createQueuedAction(
      QueuedActionEntity(
        repository: 'user',
        method: method,
        param: jsonEncode(param),
        isCritical: false,
      ),
    );
  }
}
