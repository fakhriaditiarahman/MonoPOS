class PaymentSettingsState {
  final String clientId;
  final String clientSecret;
  final String merchantId;
  final String terminalId;
  final String privateKey;
  final bool isSandbox;
  final bool isLoaded;

  const PaymentSettingsState({
    this.clientId = '',
    this.clientSecret = '',
    this.merchantId = '',
    this.terminalId = '',
    this.privateKey = '',
    this.isSandbox = true,
    this.isLoaded = false,
  });

  PaymentSettingsState copyWith({
    String? clientId,
    String? clientSecret,
    String? merchantId,
    String? terminalId,
    String? privateKey,
    bool? isSandbox,
    bool? isLoaded,
  }) {
    return PaymentSettingsState(
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      merchantId: merchantId ?? this.merchantId,
      terminalId: terminalId ?? this.terminalId,
      privateKey: privateKey ?? this.privateKey,
      isSandbox: isSandbox ?? this.isSandbox,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
