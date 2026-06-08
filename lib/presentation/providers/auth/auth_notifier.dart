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
      state = AuthState(user: result.data, isChecking: false);

      final userRepository = ref.read(userRepositoryProvider);
      final getUsecase = GetUserUsecase(userRepository);
      final existingUser = await getUsecase.call(result.data!.id);

      if (existingUser.isSuccess && existingUser.data == null) {
        final createUsecase = CreateUserUsecase(userRepository);
        await createUsecase.call(result.data!);
      }
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
