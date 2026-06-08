import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../core/services/database/database_service.dart';
import 'splash_state.dart';

final splashNotifierProvider = NotifierProvider<SplashNotifier, SplashState>(
  SplashNotifier.new,
);

class SplashNotifier extends Notifier<SplashState> {
  @override
  SplashState build() {
    return const SplashState();
  }

  Future<void> initializeApp() async {
    try {
      await DatabaseService.instance.init();
      await initializeDateFormatting();
      state = state.copyWith(isInitializing: false, isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: e.toString(),
      );
    }
  }
}
