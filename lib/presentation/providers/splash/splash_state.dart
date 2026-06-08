class SplashState {
  final bool isInitializing;
  final bool isInitialized;
  final String? errorMessage;

  const SplashState({
    this.isInitializing = true,
    this.isInitialized = false,
    this.errorMessage,
  });

  SplashState copyWith({
    bool? isInitializing,
    bool? isInitialized,
    String? errorMessage,
  }) {
    return SplashState(
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: errorMessage,
    );
  }
}
