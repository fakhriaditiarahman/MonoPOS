class CustomerFormState {
  final String? name;
  final String? phone;
  final bool isLoaded;

  const CustomerFormState({
    this.name,
    this.phone,
    this.isLoaded = false,
  });

  CustomerFormState copyWith({
    String? name,
    String? phone,
    bool? isLoaded,
  }) {
    return CustomerFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
