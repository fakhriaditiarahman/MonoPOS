import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../auth/auth_notifier.dart';
import '../products/products_notifier.dart';
import 'main_state.dart';

final mainNotifierProvider = NotifierProvider<MainNotifier, MainState>(
  MainNotifier.new,
);

class MainNotifier extends Notifier<MainState> {
  @override
  MainState build() {
    return const MainState();
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  Future<void> initMainProvider() async {
    await getUserData();
  }

  Future<void> getUserData() async {
    final userId = _requireUserId();
    final userRepository = ref.read(userRepositoryProvider);

    var res = await GetUserUsecase(userRepository).call(userId);

    if (res.isSuccess) {
      state = state.copyWith(user: res.data);
    }

    // Refresh products list
    ref.read(productsNotifierProvider.notifier).getAllProducts();

    // Notify to MainScreen
    state = state.copyWith(isLoaded: true);
  }
}
