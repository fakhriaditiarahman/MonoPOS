import '../../../core/common/result.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/user_repository.dart';
import '../datasources/local/user_local_datasource_impl.dart';
import '../models/user_model.dart';

class UserRepositoryImpl extends UserRepository {
  final UserLocalDatasourceImpl userLocalDatasource;

  UserRepositoryImpl({
    required this.userLocalDatasource,
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

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
