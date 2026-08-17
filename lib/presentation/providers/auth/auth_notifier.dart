import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';
import 'auth_state.dart';

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> signIn(String username, String password) async {
    state = state.copyWith(isChecking: true, errorMessage: null);

    final authRepository = ref.read(authRepositoryProvider);
    final usecase = SignInWithEmailPasswordUsecase(authRepository);
    final result = await usecase.call(username: username, password: password);

    if (result.isSuccess) {
      final userRepository = ref.read(userRepositoryProvider);
      final getUsecase = GetUserUsecase(userRepository);
      final existingUser = await getUsecase.call(result.data!.id);

      var loggedInUser = result.data!;

      if (existingUser.isSuccess && existingUser.data == null) {
        final createUsecase = CreateUserUsecase(userRepository);
        await createUsecase.call(loggedInUser);
      } else if (existingUser.isSuccess && existingUser.data != null) {
        // Local DB is the source of truth for roles; prefer it over the remote profile.
        final localRole = existingUser.data!.role;
        if (localRole != null && localRole != loggedInUser.role) {
          loggedInUser = loggedInUser.copyWith(role: localRole);
        }
      }

      state = AuthState(user: loggedInUser, isChecking: false);
    } else {
      state = state.copyWith(
        isChecking: false,
        errorMessage: result.error?.toString(),
      );
    }
  }

  void signOut() {
    state = const AuthState();
  }
}
