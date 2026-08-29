import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_datasource.dart';
import 'user_local_datasource_impl.dart';

class AuthLocalDataSourceImpl implements AuthDataSource {
  static const String _sessionKey = 'monopos.session_user';

  final UserLocalDatasourceImpl _userLocalDatasource;
  final SharedPreferences _sharedPreferences;

  AuthLocalDataSourceImpl(this._userLocalDatasource, this._sharedPreferences);

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
    try {
      final raw = _sharedPreferences.getString(_sessionKey);
      if (raw == null) return Result.success(data: null);

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Result.success(data: UserModel.fromJson(json));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveSession(UserModel user) async {
    try {
      final safeUser = user.copyWith(password: null);
      await _sharedPreferences.setString(_sessionKey, jsonEncode(safeUser.toJson()));
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> clearSession() async {
    try {
      await _sharedPreferences.remove(_sessionKey);
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
