class StoreSettingsState {
  final String storeName;
  final String storeAddress;
  final String receiptFooter;
  final bool isLoaded;

  const StoreSettingsState({
    this.storeName = '',
    this.storeAddress = '',
    this.receiptFooter = '',
    this.isLoaded = false,
  });

  StoreSettingsState copyWith({
    String? storeName,
    String? storeAddress,
    String? receiptFooter,
    bool? isLoaded,
  }) {
    return StoreSettingsState(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
