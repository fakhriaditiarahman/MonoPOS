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
      clientId: prefs.getString(Constants.dokuClientId) ?? '',
      clientSecret: prefs.getString(Constants.dokuClientSecret) ?? '',
      merchantId: prefs.getString(Constants.dokuMerchantId) ?? '',
      terminalId: prefs.getString(Constants.dokuTerminalId) ?? '',
      privateKey: prefs.getString(Constants.dokuPrivateKey) ?? '',
      isSandbox: prefs.getBool(Constants.dokuIsSandbox) ?? true,
      isLoaded: true,
    );
  }

  void onChangedClientId(String value) {
    state = state.copyWith(clientId: value);
    ref.read(sharedPreferencesProvider).setString(Constants.dokuClientId, value);
  }

  void onChangedClientSecret(String value) {
    state = state.copyWith(clientSecret: value);
    ref.read(sharedPreferencesProvider).setString(Constants.dokuClientSecret, value);
  }

  void onChangedMerchantId(String value) {
    state = state.copyWith(merchantId: value);
    ref.read(sharedPreferencesProvider).setString(Constants.dokuMerchantId, value);
  }

  void onChangedTerminalId(String value) {
    state = state.copyWith(terminalId: value);
    ref.read(sharedPreferencesProvider).setString(Constants.dokuTerminalId, value);
  }

  void onChangedPrivateKey(String value) {
    state = state.copyWith(privateKey: value);
    ref.read(sharedPreferencesProvider).setString(Constants.dokuPrivateKey, value);
  }

  void onChangedIsSandbox(bool value) {
    state = state.copyWith(isSandbox: value);
    ref.read(sharedPreferencesProvider).setBool(Constants.dokuIsSandbox, value);
  }
}
