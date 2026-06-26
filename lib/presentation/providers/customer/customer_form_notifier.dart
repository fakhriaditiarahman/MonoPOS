import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/usecases/customer_usecases.dart';
import 'customer_form_state.dart';
import 'customer_notifier.dart';

final customerFormNotifierProvider = NotifierProvider.autoDispose<CustomerFormNotifier, CustomerFormState>(
  CustomerFormNotifier.new,
);

class CustomerFormNotifier extends AutoDisposeNotifier<CustomerFormState> {
  @override
  CustomerFormState build() {
    return const CustomerFormState();
  }

  Future<void> initCustomerForm(String? customerId) async {
    if (customerId == null) {
      state = state.copyWith(isLoaded: true);
      return;
    }

    final customerRepository = ref.read(customerRepositoryProvider);
    var res = await GetCustomerUsecase(customerRepository).call(customerId);

    if (res.isSuccess && res.data != null) {
      var customer = res.data!;
      state = state.copyWith(
        name: customer.name,
        phone: customer.phone,
        type: customer.type,
        creditLimit: customer.creditLimit,
        isLoaded: true,
      );
    } else {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<Result<String>> createCustomer() async {
    try {
      final customerRepository = ref.read(customerRepositoryProvider);
      var customer = CustomerEntity(
        name: state.name ?? '',
        phone: state.phone,
        type: state.type,
        creditLimit: state.creditLimit,
      );

      var res = await CreateCustomerUsecase(customerRepository).call(customer);

      ref.read(customerNotifierProvider.notifier).getAllCustomers();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<Result<void>> updateCustomer(String id) async {
    try {
      final customerRepository = ref.read(customerRepositoryProvider);
      var customer = CustomerEntity(
        id: id,
        name: state.name ?? '',
        phone: state.phone,
        type: state.type,
        creditLimit: state.creditLimit,
      );

      var res = await UpdateCustomerUsecase(customerRepository).call(customer);

      ref.read(customerNotifierProvider.notifier).getAllCustomers();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  void onChangedName(String value) {
    state = state.copyWith(name: value);
  }

  void onChangedPhone(String value) {
    state = state.copyWith(phone: value.isEmpty ? null : value);
  }

  void onChangedType(String value) {
    state = state.copyWith(type: value);
  }

  void onChangedCreditLimit(String value) {
    state = state.copyWith(creditLimit: int.tryParse(value) ?? 0);
  }
}
