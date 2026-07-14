import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import 'payment_settings_state.dart';

final paymentSettingsNotifierProvider = NotifierProvider.autoDispose<PaymentSettingsNotifier, PaymentSettingsState>(
  PaymentSettingsNotifier.new,
);

class PaymentSettingsNotifier extends AutoDisposeNotifier<PaymentSettingsState> {
  String _originalClientId = '';
  String _originalClientSecret = '';
  String _originalMerchantId = '';
  String _originalTerminalId = '';
  String _originalPrivateKey = '';
  bool _originalIsSandbox = true;

  @override
  PaymentSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);

    final clientId = prefs.getString(Constants.dokuClientId) ?? '';
    final clientSecret = prefs.getString(Constants.dokuClientSecret) ?? '';
    final merchantId = prefs.getString(Constants.dokuMerchantId) ?? '';
    final terminalId = prefs.getString(Constants.dokuTerminalId) ?? '';
    final privateKey = prefs.getString(Constants.dokuPrivateKey) ?? '';
    final isSandbox = prefs.getBool(Constants.dokuIsSandbox) ?? true;

    _originalClientId = clientId;
    _originalClientSecret = clientSecret;
    _originalMerchantId = merchantId;
    _originalTerminalId = terminalId;
    _originalPrivateKey = privateKey;
    _originalIsSandbox = isSandbox;

    return PaymentSettingsState(
      clientId: clientId,
      clientSecret: clientSecret,
      merchantId: merchantId,
      terminalId: terminalId,
      privateKey: privateKey,
      isSandbox: isSandbox,
      isLoaded: true,
    );
  }

  void onChangedClientId(String value) {
    state = state.copyWith(clientId: value);
    _updateHasChanges();
  }

  void onChangedClientSecret(String value) {
    state = state.copyWith(clientSecret: value);
    _updateHasChanges();
  }

  void onChangedMerchantId(String value) {
    state = state.copyWith(merchantId: value);
    _updateHasChanges();
  }

  void onChangedTerminalId(String value) {
    state = state.copyWith(terminalId: value);
    _updateHasChanges();
  }

  void onChangedPrivateKey(String value) {
    state = state.copyWith(privateKey: value);
    _updateHasChanges();
  }

  void onChangedIsSandbox(bool value) {
    state = state.copyWith(isSandbox: value);
    _updateHasChanges();
  }

  void _updateHasChanges() {
    final hasChanges =
        state.clientId != _originalClientId ||
        state.clientSecret != _originalClientSecret ||
        state.merchantId != _originalMerchantId ||
        state.terminalId != _originalTerminalId ||
        state.privateKey != _originalPrivateKey ||
        state.isSandbox != _originalIsSandbox;

    if (hasChanges != state.hasChanges) {
      state = state.copyWith(hasChanges: hasChanges);
    }
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(Constants.dokuClientId, state.clientId);
    await prefs.setString(Constants.dokuClientSecret, state.clientSecret);
    await prefs.setString(Constants.dokuMerchantId, state.merchantId);
    await prefs.setString(Constants.dokuTerminalId, state.terminalId);
    await prefs.setString(Constants.dokuPrivateKey, state.privateKey);
    await prefs.setBool(Constants.dokuIsSandbox, state.isSandbox);

    _originalClientId = state.clientId;
    _originalClientSecret = state.clientSecret;
    _originalMerchantId = state.merchantId;
    _originalTerminalId = state.terminalId;
    _originalPrivateKey = state.privateKey;
    _originalIsSandbox = state.isSandbox;

    state = state.copyWith(isSaving: false, hasChanges: false);
  }
}
