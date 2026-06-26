import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/interfaces/auth_datasource.dart';
import '../datasources/local/auth_local_datasource_impl.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSourceImpl authLocalDataSource;
  final AuthDataSource? authRemoteDataSource;

  AuthRepositoryImpl({
    required this.authLocalDataSource,
    this.authRemoteDataSource,
  });

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      final remote = authRemoteDataSource;
      if (remote != null) {
        final res = await remote.signInWithGoogle();
        if (res.isSuccess) return Result.success(data: res.data!.toEntity());
      }

      final res = await authLocalDataSource.signInWithGoogle();
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: res.data!.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserEntity>> signInWithEmailPassword({
    required String username,
    required String password,
  }) async {
    try {
      UserEntity? localUser;

      if (authRemoteDataSource != null) {
        final remoteRes = await authRemoteDataSource!.signInWithEmailPassword(
          username: username,
          password: password,
        );
        if (remoteRes.isSuccess) return Result.success(data: remoteRes.data!.toEntity());

        // Remote auth failed — try local
        final localRes = await authLocalDataSource.signInWithEmailPassword(
          username: username,
          password: password,
        );
        if (localRes.isSuccess) localUser = localRes.data!.toEntity();
      } else {
        final localRes = await authLocalDataSource.signInWithEmailPassword(
          username: username,
          password: password,
        );
        if (localRes.isSuccess) localUser = localRes.data!.toEntity();
      }

      if (localUser == null) {
        return Result.failure(error: 'Login gagal');
      }

      // Best-effort: ensure Supabase Auth session for future sync
      _ensureSupabaseAuth(username, password);

      return Result.success(data: localUser);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _ensureSupabaseAuth(String username, String password) async {
    try {
      final remote = authRemoteDataSource;
      if (remote == null) return;

      await remote.signInWithEmailPassword(
        username: username,
        password: password,
      );
    } catch (e) {
      cl('Supabase auth best-effort failed: $e');
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await authRemoteDataSource?.signOut();

      final res = await authLocalDataSource.signOut();
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      final remote = authRemoteDataSource;
      if (remote != null) {
        final res = await remote.getCurrentUser();
        if (res.isSuccess && res.data != null) return Result.success(data: res.data!.toEntity());
      }

      final res = await authLocalDataSource.getCurrentUser();
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: res.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
