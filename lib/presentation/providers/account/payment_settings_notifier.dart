import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import 'payment_settings_state.dart';

final paymentSettingsNotifierProvider = NotifierProvider.autoDispose<PaymentSettingsNotifier, PaymentSettingsState>(
  PaymentSettingsNotifier.new,
);

class PaymentSettingsNotifier extends AutoDisposeNotifier<PaymentSettingsState> {
  String _originalApiKey = '';
  String _originalMerchantId = '';
  bool _originalIsSandbox = true;

  @override
  PaymentSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);

    final apiKey = prefs.getString(Constants.klikQrisApiKey) ?? '';
    final merchantId = prefs.getString(Constants.klikQrisMerchantId) ?? '';
    final isSandbox = prefs.getBool(Constants.klikQrisIsSandbox) ?? true;

    _originalApiKey = apiKey;
    _originalMerchantId = merchantId;
    _originalIsSandbox = isSandbox;

    return PaymentSettingsState(
      apiKey: apiKey,
      merchantId: merchantId,
      isSandbox: isSandbox,
      isLoaded: true,
    );
  }

  void onChangedApiKey(String value) {
    state = state.copyWith(apiKey: value);
    _updateHasChanges();
  }

  void onChangedMerchantId(String value) {
    state = state.copyWith(merchantId: value);
    _updateHasChanges();
  }

  void onChangedIsSandbox(bool value) {
    state = state.copyWith(isSandbox: value);
    _updateHasChanges();
  }

  void _updateHasChanges() {
    final hasChanges =
        state.apiKey != _originalApiKey ||
        state.merchantId != _originalMerchantId ||
        state.isSandbox != _originalIsSandbox;

    if (hasChanges != state.hasChanges) {
      state = state.copyWith(hasChanges: hasChanges);
    }
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(Constants.klikQrisApiKey, state.apiKey);
    await prefs.setString(Constants.klikQrisMerchantId, state.merchantId);
    await prefs.setBool(Constants.klikQrisIsSandbox, state.isSandbox);

    _originalApiKey = state.apiKey;
    _originalMerchantId = state.merchantId;
    _originalIsSandbox = state.isSandbox;

    state = state.copyWith(isSaving: false, hasChanges: false);
  }
}
