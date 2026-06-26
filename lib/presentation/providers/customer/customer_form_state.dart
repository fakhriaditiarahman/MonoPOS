class CustomerFormState {
  final String? name;
  final String? phone;
  final String type;
  final int creditLimit;
  final bool isLoaded;

  const CustomerFormState({
    this.name,
    this.phone,
    this.type = 'retail',
    this.creditLimit = 0,
    this.isLoaded = false,
  });

  CustomerFormState copyWith({
    String? name,
    String? phone,
    String? type,
    int? creditLimit,
    bool? isLoaded,
  }) {
    return CustomerFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      creditLimit: creditLimit ?? this.creditLimit,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
