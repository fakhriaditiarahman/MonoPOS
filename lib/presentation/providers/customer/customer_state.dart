import '../../../domain/entities/customer_entity.dart';

class CustomerState {
  final List<CustomerEntity> customers;
  final bool isLoading;
  final bool isLoaded;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.isLoaded = false,
  });

  CustomerState copyWith({
    List<CustomerEntity>? customers,
    bool? isLoading,
    bool? isLoaded,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
