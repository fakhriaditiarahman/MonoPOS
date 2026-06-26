import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/usecases/customer_usecases.dart';
import 'customer_state.dart';

final customerNotifierProvider = NotifierProvider<CustomerNotifier, CustomerState>(
  CustomerNotifier.new,
);

class CustomerNotifier extends Notifier<CustomerState> {
  @override
  CustomerState build() {
    return const CustomerState(isLoading: true);
  }

  Future<void> getAllCustomers() async {
    state = state.copyWith(isLoading: true);

    final customerRepository = ref.read(customerRepositoryProvider);
    var res = await GetAllCustomersUsecase(customerRepository).call(null);

    if (res.isSuccess) {
      state = state.copyWith(
        customers: res.data!,
        isLoading: false,
        isLoaded: true,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Result<String>> createCustomer(CustomerEntity customer) async {
    final customerRepository = ref.read(customerRepositoryProvider);
    var res = await CreateCustomerUsecase(customerRepository).call(customer);

    if (res.isSuccess) {
      await getAllCustomers();
    }

    return res;
  }

  Future<Result<void>> updateCustomer(CustomerEntity customer) async {
    final customerRepository = ref.read(customerRepositoryProvider);
    var res = await UpdateCustomerUsecase(customerRepository).call(customer);

    if (res.isSuccess) {
      await getAllCustomers();
    }

    return res;
  }

  Future<Result<void>> deleteCustomer(String id) async {
    final customerRepository = ref.read(customerRepositoryProvider);
    var res = await DeleteCustomerUsecase(customerRepository).call(id);

    if (res.isSuccess) {
      await getAllCustomers();
    }

    return res;
  }

  Future<List<CustomerEntity>> searchCustomers(String query) async {
    if (query.isEmpty) {
      final customerRepository = ref.read(customerRepositoryProvider);
      var res = await GetAllCustomersUsecase(customerRepository).call(null);
      return res.data ?? [];
    }

    final customerRepository = ref.read(customerRepositoryProvider);
    var res = await SearchCustomersUsecase(customerRepository).call(query);
    return res.data ?? [];
  }
}
