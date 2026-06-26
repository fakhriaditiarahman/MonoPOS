import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../../models/receivable_payment_model.dart';
import '../interfaces/receivable_payment_datasource.dart';

class ReceivablePaymentLocalDatasourceImpl extends ReceivablePaymentDatasource {
  final DatabaseService _databaseService;

  ReceivablePaymentLocalDatasourceImpl(this._databaseService);

  @override
  Future<Result<int>> createPayment(ReceivablePaymentModel payment) async {
    try {
      await _databaseService.database.insert(
        DatabaseConfig.receivablePaymentTableName,
        payment.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return Result.success(data: payment.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ReceivablePaymentModel>>> getPaymentsByTransaction(int transactionId) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.receivablePaymentTableName,
        where: 'transactionId = ?',
        whereArgs: [transactionId],
        orderBy: 'createdAt ASC',
      );

      return Result.success(
        data: res.map((e) => ReceivablePaymentModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ReceivablePaymentModel>>> getPaymentsByCustomer(String customerId) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.receivablePaymentTableName,
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'createdAt DESC',
      );

      return Result.success(
        data: res.map((e) => ReceivablePaymentModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
