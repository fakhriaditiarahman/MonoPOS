import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/receivable_payment_model.dart';
import '../interfaces/receivable_payment_datasource.dart';

class ReceivablePaymentRemoteDatasourceImpl extends ReceivablePaymentDatasource {
  ReceivablePaymentRemoteDatasourceImpl({SupabaseClient? clientOverride}) : _clientOverride = clientOverride;

  final SupabaseClient? _clientOverride;

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  @override
  Future<Result<int>> createPayment(ReceivablePaymentModel payment) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.receivablePaymentsTable).insert(payment.toJson());

      return Result.success(data: payment.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ReceivablePaymentModel>>> getPaymentsByTransaction(int transactionId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client
          .from(SupabaseConfig.receivablePaymentsTable)
          .select()
          .eq('transactionId', transactionId)
          .order('createdAt', ascending: true);

      return Result.success(
        data: res.map((e) => ReceivablePaymentModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ReceivablePaymentModel>>> getPaymentsByCustomer(String customerId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client
          .from(SupabaseConfig.receivablePaymentsTable)
          .select()
          .eq('customerId', customerId)
          .order('createdAt', ascending: false);

      return Result.success(
        data: res.map((e) => ReceivablePaymentModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
