class StoreSettingsState {
  final String storeName;
  final String storeAddress;
  final String receiptFooter;
  final bool isLoaded;
  final bool hasChanges;
  final bool isSaving;

  const StoreSettingsState({
    this.storeName = '',
    this.storeAddress = '',
    this.receiptFooter = '',
    this.isLoaded = false,
    this.hasChanges = false,
    this.isSaving = false,
  });

  StoreSettingsState copyWith({
    String? storeName,
    String? storeAddress,
    String? receiptFooter,
    bool? isLoaded,
    bool? hasChanges,
    bool? isSaving,
  }) {
    return StoreSettingsState(
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      isLoaded: isLoaded ?? this.isLoaded,
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
