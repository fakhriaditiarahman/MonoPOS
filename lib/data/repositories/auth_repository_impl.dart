import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/interfaces/auth_datasource.dart';
import '../datasources/local/auth_local_datasource_impl.dart';

// ignore_for_file: depend_on_referenced_packages

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
        if (res.isSuccess) {
          await authLocalDataSource.saveSession(res.data!);
          return Result.success(data: res.data!.toEntity());
        }
      }

      final res = await authLocalDataSource.signInWithGoogle();
      if (res.isFailure) return Result.failure(error: res.error!);

      await authLocalDataSource.saveSession(res.data!);
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
        cl('[AuthRepo] Remote datasource exists, trying remote first');
        final remoteRes = await authRemoteDataSource!.signInWithEmailPassword(
          username: username,
          password: password,
        );
        if (remoteRes.isSuccess) {
          cl('[AuthRepo] Remote auth success');
          await authLocalDataSource.saveSession(remoteRes.data!);
          return Result.success(data: remoteRes.data!.toEntity());
        }

        cl('[AuthRepo] Remote auth failed: ${remoteRes.error}, trying local fallback');
        final localRes = await authLocalDataSource.signInWithEmailPassword(
          username: username,
          password: password,
        );
        if (localRes.isSuccess) {
          localUser = localRes.data!.toEntity();
          cl('[AuthRepo] Local fallback success for: $username');
          await authLocalDataSource.saveSession(localRes.data!);
        } else {
          cl('[AuthRepo] Local fallback also failed: ${localRes.error}');
        }
      } else {
        cl('[AuthRepo] No remote datasource, using local only');
        final localRes = await authLocalDataSource.signInWithEmailPassword(
          username: username,
          password: password,
        );
        if (localRes.isSuccess) {
          localUser = localRes.data!.toEntity();
          cl('[AuthRepo] Local auth success for: $username');
          await authLocalDataSource.saveSession(localRes.data!);
        } else {
          cl('[AuthRepo] Local auth failed: ${localRes.error}');
        }
      }

      if (localUser == null) {
        cl('[AuthRepo] Login failed for: $username — no user returned from any datasource');
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

      final sessionRes = await authLocalDataSource.clearSession();
      if (sessionRes.isFailure) return Result.failure(error: sessionRes.error!);

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
