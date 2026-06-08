import '../../../core/common/result.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_datasource.dart';

class AuthLocalDataSourceImpl implements AuthDataSource {
  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    return Result.success(
      data: UserModel(
        id: 'local-user-id',
        name: 'Admin',
        email: 'admin@localhost',
        authProvider: 'local',
      ),
    );
  }

  @override
  Future<Result<void>> signOut() async {
    return Result.success(data: null);
  }

  @override
  Future<Result<UserModel?>> getCurrentUser() async {
    return Result.success(
      data: UserModel(
        id: 'local-user-id',
        name: 'Admin',
        email: 'admin@localhost',
        authProvider: 'local',
      ),
    );
  }
}
