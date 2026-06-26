import '../../core/common/result.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<Result<CustomerEntity?>> getCustomer(String id);

  Future<Result<String>> createCustomer(CustomerEntity customer);

  Future<Result<void>> updateCustomer(CustomerEntity customer);

  Future<Result<void>> deleteCustomer(String id);

  Future<Result<List<CustomerEntity>>> getAllCustomers();

  Future<Result<List<CustomerEntity>>> searchCustomers(String query);
}
