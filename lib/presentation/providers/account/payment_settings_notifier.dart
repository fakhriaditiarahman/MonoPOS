import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import 'payment_settings_state.dart';

final paymentSettingsNotifierProvider = NotifierProvider.autoDispose<PaymentSettingsNotifier, PaymentSettingsState>(
  PaymentSettingsNotifier.new,
);

class PaymentSettingsNotifier extends AutoDisposeNotifier<PaymentSettingsState> {
  @override
  PaymentSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return PaymentSettingsState(
      serverKey: prefs.getString(Constants.midtransServerKey) ?? '',
      clientKey: prefs.getString(Constants.midtransClientKey) ?? '',
      isProduction: prefs.getBool(Constants.midtransIsProduction) ?? false,
      merchantName: prefs.getString(Constants.midtransMerchantName) ?? '',
      isLoaded: true,
    );
  }

  void onChangedServerKey(String value) {
    state = state.copyWith(serverKey: value);
    ref.read(sharedPreferencesProvider).setString(Constants.midtransServerKey, value);
  }

  void onChangedClientKey(String value) {
    state = state.copyWith(clientKey: value);
    ref.read(sharedPreferencesProvider).setString(Constants.midtransClientKey, value);
  }

  void onChangedMerchantName(String value) {
    state = state.copyWith(merchantName: value);
    ref.read(sharedPreferencesProvider).setString(Constants.midtransMerchantName, value);
  }

  void onChangedIsProduction(bool value) {
    state = state.copyWith(isProduction: value);
    ref.read(sharedPreferencesProvider).setBool(Constants.midtransIsProduction, value);
  }
}
