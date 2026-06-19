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
      apiKey: prefs.getString(Constants.qrisApiKey) ?? '',
      mid: prefs.getString(Constants.qrisMid) ?? '',
      merchantName: prefs.getString(Constants.qrisMerchantName) ?? '',
      isLoaded: true,
    );
  }

  void onChangedApiKey(String value) {
    state = state.copyWith(apiKey: value);
    ref.read(sharedPreferencesProvider).setString(Constants.qrisApiKey, value);
  }

  void onChangedMid(String value) {
    state = state.copyWith(mid: value);
    ref.read(sharedPreferencesProvider).setString(Constants.qrisMid, value);
  }

  void onChangedMerchantName(String value) {
    state = state.copyWith(merchantName: value);
    ref.read(sharedPreferencesProvider).setString(Constants.qrisMerchantName, value);
  }
}
