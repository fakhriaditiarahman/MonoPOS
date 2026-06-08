import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/user_entity.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState(
      user: UserEntity(
        id: 'local-user-id',
        name: 'Admin',
        email: 'admin@localhost',
        authProvider: AuthProvider.local,
      ),
    );
  }
}
