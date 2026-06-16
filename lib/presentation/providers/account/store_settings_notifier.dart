import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import 'store_settings_state.dart';

final storeSettingsNotifierProvider = NotifierProvider.autoDispose<StoreSettingsNotifier, StoreSettingsState>(
  StoreSettingsNotifier.new,
);

class StoreSettingsNotifier extends AutoDisposeNotifier<StoreSettingsState> {
  @override
  StoreSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return StoreSettingsState(
      storeName: prefs.getString(Constants.storeNameKey) ?? '',
      storeAddress: prefs.getString(Constants.storeAddressKey) ?? '',
      receiptFooter: prefs.getString(Constants.receiptFooterKey) ?? '',
      isLoaded: true,
    );
  }

  void onChangedStoreName(String value) {
    state = state.copyWith(storeName: value);
    ref.read(sharedPreferencesProvider).setString(Constants.storeNameKey, value);
  }

  void onChangedStoreAddress(String value) {
    state = state.copyWith(storeAddress: value);
    ref.read(sharedPreferencesProvider).setString(Constants.storeAddressKey, value);
  }

  void onChangedReceiptFooter(String value) {
    state = state.copyWith(receiptFooter: value);
    ref.read(sharedPreferencesProvider).setString(Constants.receiptFooterKey, value);
  }
}
