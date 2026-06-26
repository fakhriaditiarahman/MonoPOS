import '../../../core/common/result.dart';
import '../../models/customer_model.dart';

abstract class CustomerDatasource {
  Future<Result<CustomerModel?>> getCustomer(String id);

  Future<Result<String>> createCustomer(CustomerModel customer);

  Future<Result<void>> updateCustomer(CustomerModel customer);

  Future<Result<void>> deleteCustomer(String id);

  Future<Result<List<CustomerModel>>> getAllCustomers();

  Future<Result<List<CustomerModel>>> searchCustomers(String query);
}
