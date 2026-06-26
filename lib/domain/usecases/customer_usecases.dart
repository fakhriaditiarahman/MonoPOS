import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer_entity.dart';
import '../repositories/customer_repository.dart';

class GetCustomerUsecase extends Usecase<Result, String> {
  GetCustomerUsecase(this._customerRepository);

  final CustomerRepository _customerRepository;

  @override
  Future<Result<CustomerEntity?>> call(String params) async => _customerRepository.getCustomer(params);
}

class CreateCustomerUsecase extends Usecase<Result, CustomerEntity> {
  CreateCustomerUsecase(this._customerRepository);

  final CustomerRepository _customerRepository;

  @override
  Future<Result<String>> call(CustomerEntity params) async => _customerRepository.createCustomer(params);
}

class UpdateCustomerUsecase extends Usecase<Result<void>, CustomerEntity> {
  UpdateCustomerUsecase(this._customerRepository);

  final CustomerRepository _customerRepository;

  @override
  Future<Result<void>> call(CustomerEntity params) async => _customerRepository.updateCustomer(params);
}

class DeleteCustomerUsecase extends Usecase<Result<void>, String> {
  DeleteCustomerUsecase(this._customerRepository);

  final CustomerRepository _customerRepository;

  @override
  Future<Result<void>> call(String params) async => _customerRepository.deleteCustomer(params);
}

class GetAllCustomersUsecase extends Usecase<Result, void> {
  GetAllCustomersUsecase(this._customerRepository);

  final CustomerRepository _customerRepository;

  @override
  Future<Result<List<CustomerEntity>>> call(void params) async => _customerRepository.getAllCustomers();
}

class SearchCustomersUsecase extends Usecase<Result, String> {
  SearchCustomersUsecase(this._customerRepository);

  final CustomerRepository _customerRepository;

  @override
  Future<Result<List<CustomerEntity>>> call(String params) async => _customerRepository.searchCustomers(params);
}
