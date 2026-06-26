import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/user_model.dart';
import '../interfaces/user_datasource.dart';

class UserRemoteDatasourceImpl extends UserDatasource {
  UserRemoteDatasourceImpl();

  SupabaseClient? get _client => SupabaseService.client;

  @override
  Future<Result<String>> createUser(UserModel user) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = user.toJson()..remove('password');

      await client.from(SupabaseConfig.usersTable).upsert(json);

      return Result.success(data: user.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateUser(UserModel user) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = user.toJson()..remove('password');

      await client.from(SupabaseConfig.usersTable).update(json).eq('id', user.id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteUser(String id) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.usersTable).delete().eq('id', id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserModel?>> getUser(String id) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.usersTable).select().eq('id', id).maybeSingle();

      if (res == null) return Result.success(data: null);

      return Result.success(
        data: UserModel.fromJson(Map<String, dynamic>.from(res)),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<UserModel>>> getAllUsers() async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client.from(SupabaseConfig.usersTable).select();

      return Result.success(
        data: (res as List).map((e) => UserModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserModel?>> getUserByUsername(String username) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.usersTable).select().eq('id', username).maybeSingle();

      if (res == null) return Result.success(data: null);

      return Result.success(
        data: UserModel.fromJson(Map<String, dynamic>.from(res)),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
