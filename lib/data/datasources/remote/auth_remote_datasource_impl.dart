import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_datasource.dart';

class AuthRemoteDataSourceImpl implements AuthDataSource {
  AuthRemoteDataSourceImpl();

  SupabaseClient? get _client => SupabaseService.client;

  @override
  Future<Result<UserModel>> signInWithGoogle() async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.monopos.app://callback',
      );

      final session = client.auth.currentSession;
      if (session == null) return Result.failure(error: 'No session after Google sign-in');

      final user = session.user;
      final profile = await _fetchOrCreateProfile(client, user);

      return Result.success(data: profile);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserModel>> signInWithEmailPassword({
    required String username,
    required String password,
  }) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final email = username.contains('@') ? username : '$username@monopos.local';

      try {
        final res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = res.user;
        if (user == null) return Result.failure(error: 'Login gagal');

        final profile = await _fetchOrCreateProfile(client, user);
        return Result.success(data: profile);
      } on AuthException catch (e) {
        if (e.code != 'invalid_credentials') return Result.failure(error: e);

        await client.auth.signUp(
          email: email,
          password: password,
        );

        final res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = res.user;
        if (user == null) return Result.failure(error: 'Login gagal setelah registrasi');

        final profile = await _fetchOrCreateProfile(client, user);
        return Result.success(data: profile);
      }
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<UserModel> _fetchOrCreateProfile(SupabaseClient client, User user) async {
    final profileRes = await client.from(SupabaseConfig.usersTable).select().eq('id', user.id).maybeSingle();

    if (profileRes != null) {
      return UserModel.fromJson(Map<String, dynamic>.from(profileRes));
    }

    final newProfile = UserModel(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] ?? user.email,
      authProvider: 'supabase',
      role: 'kasir',
    );

    await client.from(SupabaseConfig.usersTable).insert(newProfile.toJson()..remove('password'));

    return newProfile;
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      await client.auth.signOut();
      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<UserModel?>> getCurrentUser() async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final user = client.auth.currentUser;
      if (user == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.usersTable).select().eq('id', user.id).maybeSingle();

      if (res == null) return Result.success(data: null);

      return Result.success(
        data: UserModel.fromJson(Map<String, dynamic>.from(res)),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
