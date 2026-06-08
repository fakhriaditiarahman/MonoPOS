import '../../../core/common/result.dart';
import '../../models/user_model.dart';

abstract class AuthDataSource {
  Future<Result<UserModel>> signInWithGoogle();

  Future<Result<UserModel>> signInWithEmailPassword({
    required String username,
    required String password,
  });

  Future<Result<void>> signOut();

  Future<Result<UserModel?>> getCurrentUser();
}
