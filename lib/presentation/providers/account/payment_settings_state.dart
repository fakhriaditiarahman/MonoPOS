class PaymentSettingsState {
  final String apiKey;
  final String mid;
  final String merchantName;
  final bool isLoaded;

  const PaymentSettingsState({
    this.apiKey = '',
    this.mid = '',
    this.merchantName = '',
    this.isLoaded = false,
  });

  PaymentSettingsState copyWith({
    String? apiKey,
    String? mid,
    String? merchantName,
    bool? isLoaded,
  }) {
    return PaymentSettingsState(
      apiKey: apiKey ?? this.apiKey,
      mid: mid ?? this.mid,
      merchantName: merchantName ?? this.merchantName,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
