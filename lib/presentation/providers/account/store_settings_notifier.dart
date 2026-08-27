import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import 'store_settings_state.dart';

final storeSettingsNotifierProvider = NotifierProvider.autoDispose<StoreSettingsNotifier, StoreSettingsState>(
  StoreSettingsNotifier.new,
);

class StoreSettingsNotifier extends AutoDisposeNotifier<StoreSettingsState> {
  String _originalStoreName = '';
  String _originalStoreAddress = '';
  String _originalReceiptFooter = '';

  @override
  StoreSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);

    final storeName = prefs.getString(Constants.storeNameKey) ?? '';
    final storeAddress = prefs.getString(Constants.storeAddressKey) ?? '';
    final receiptFooter = prefs.getString(Constants.receiptFooterKey) ?? '';

    _originalStoreName = storeName;
    _originalStoreAddress = storeAddress;
    _originalReceiptFooter = receiptFooter;

    return StoreSettingsState(
      storeName: storeName,
      storeAddress: storeAddress,
      receiptFooter: receiptFooter,
      isLoaded: true,
    );
  }

  void onChangedStoreName(String value) {
    state = state.copyWith(storeName: value);
    _updateHasChanges();
  }

  void onChangedStoreAddress(String value) {
    state = state.copyWith(storeAddress: value);
    _updateHasChanges();
  }

  void onChangedReceiptFooter(String value) {
    state = state.copyWith(receiptFooter: value);
    _updateHasChanges();
  }

  void _updateHasChanges() {
    final hasChanges =
        state.storeName != _originalStoreName ||
        state.storeAddress != _originalStoreAddress ||
        state.receiptFooter != _originalReceiptFooter;

    if (hasChanges != state.hasChanges) {
      state = state.copyWith(hasChanges: hasChanges);
    }
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true);

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(Constants.storeNameKey, state.storeName);
    await prefs.setString(Constants.storeAddressKey, state.storeAddress);
    await prefs.setString(Constants.receiptFooterKey, state.receiptFooter);

    _originalStoreName = state.storeName;
    _originalStoreAddress = state.storeAddress;
    _originalReceiptFooter = state.receiptFooter;

    state = state.copyWith(isSaving: false, hasChanges: false);
  }
}
