import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/customer_model.dart';
import '../interfaces/customer_datasource.dart';

class CustomerRemoteDatasourceImpl extends CustomerDatasource {
  CustomerRemoteDatasourceImpl({SupabaseClient? clientOverride}) : _clientOverride = clientOverride;

  final SupabaseClient? _clientOverride;

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  @override
  Future<Result<CustomerModel?>> getCustomer(String id) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.customersTable).select().eq('id', id).maybeSingle();

      if (res == null) return Result.success(data: null);

      return Result.success(data: CustomerModel.fromJson(Map<String, dynamic>.from(res)));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> createCustomer(CustomerModel customer) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.customersTable).insert(customer.toJson());

      return Result.success(data: customer.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCustomer(CustomerModel customer) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.customersTable).update(customer.toJson()).eq('id', customer.id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCustomer(String id) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.customersTable).delete().eq('id', id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<CustomerModel>>> getAllCustomers() async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client.from(SupabaseConfig.customersTable).select().order('name', ascending: true);

      return Result.success(
        data: res.map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<CustomerModel>>> searchCustomers(String query) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client
          .from(SupabaseConfig.customersTable)
          .select()
          .or('name.ilike.%$query%,phone.ilike.%$query%')
          .order('name', ascending: true);

      return Result.success(
        data: res.map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
