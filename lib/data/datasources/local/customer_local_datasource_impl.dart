import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../../models/customer_model.dart';
import '../interfaces/customer_datasource.dart';

class CustomerLocalDatasourceImpl extends CustomerDatasource {
  final DatabaseService _databaseService;

  CustomerLocalDatasourceImpl(this._databaseService);

  @override
  Future<Result<CustomerModel?>> getCustomer(String id) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.customerTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (res.isEmpty) return Result.success(data: null);

      return Result.success(data: CustomerModel.fromJson(res.first));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> createCustomer(CustomerModel customer) async {
    try {
      await _databaseService.database.insert(
        DatabaseConfig.customerTableName,
        customer.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return Result.success(data: customer.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateCustomer(CustomerModel customer) async {
    try {
      await _databaseService.database.update(
        DatabaseConfig.customerTableName,
        customer.toJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteCustomer(String id) async {
    try {
      await _databaseService.database.delete(
        DatabaseConfig.customerTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<CustomerModel>>> getAllCustomers() async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.customerTableName,
        orderBy: 'name ASC',
      );

      return Result.success(
        data: res.map((e) => CustomerModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<CustomerModel>>> searchCustomers(String query) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.customerTableName,
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );

      return Result.success(
        data: res.map((e) => CustomerModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
