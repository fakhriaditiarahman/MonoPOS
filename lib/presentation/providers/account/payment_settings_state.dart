class PaymentSettingsState {
  final String serverKey;
  final String clientKey;
  final bool isProduction;
  final String merchantName;
  final bool isLoaded;

  const PaymentSettingsState({
    this.serverKey = '',
    this.clientKey = '',
    this.isProduction = false,
    this.merchantName = '',
    this.isLoaded = false,
  });

  PaymentSettingsState copyWith({
    String? serverKey,
    String? clientKey,
    bool? isProduction,
    String? merchantName,
    bool? isLoaded,
  }) {
    return PaymentSettingsState(
      serverKey: serverKey ?? this.serverKey,
      clientKey: clientKey ?? this.clientKey,
      isProduction: isProduction ?? this.isProduction,
      merchantName: merchantName ?? this.merchantName,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
