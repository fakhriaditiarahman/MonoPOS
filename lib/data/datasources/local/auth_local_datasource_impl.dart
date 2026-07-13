import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_datasource.dart';
import 'user_local_datasource_impl.dart';

class AuthLocalDataSourceImpl implements AuthDataSource {
  final UserLocalDatasourceImpl _userLocalDatasource;

  AuthLocalDataSourceImpl(this._userLocalDatasource);

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    return Result.success(
      data: UserModel(
        id: 'local-user-id',
        name: 'Admin',
        email: 'admin@localhost',
        authProvider: 'local',
        role: 'admin',
      ),
    );
  }

  @override
  Future<Result<UserModel>> signInWithEmailPassword({
    required String username,
    required String password,
  }) async {
    final result = await _userLocalDatasource.getUserByUsername(username);

    if (result.isFailure) {
      return Result.failure(error: 'Terjadi kesalahan sistem!');
    }

    final user = result.data;
    if (user == null) {
      cl('[AuthLocal] User not found: "$username"');
      return Result.failure(error: 'Username atau password salah!');
    }

    if (user.password != password) {
      cl('[AuthLocal] Password mismatch: db="${user.password}" vs input="$password"');
      return Result.failure(error: 'Username atau password salah!');
    }

    return Result.success(data: user);
  }

  @override
  Future<Result<void>> signOut() async {
    return Result.success(data: null);
  }

  @override
  Future<Result<UserModel?>> getCurrentUser() async {
    return Result.success(data: null);
  }
}
