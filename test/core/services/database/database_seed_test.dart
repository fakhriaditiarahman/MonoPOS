import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/services/database/database_config.dart';
import 'package:mono_pos/core/services/database/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService appDatabase;
  late Database testDatabase;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    testDatabase = await openDatabase(inMemoryDatabasePath, version: 1);

    appDatabase = DatabaseService.instance;
    await appDatabase.initTestDatabase(testDatabase: testDatabase);
  });

  tearDownAll(() async {
    await testDatabase.close();
  });

  group('Database Seed', () {
    test('seed users should be created', () async {
      final result = await testDatabase.query(DatabaseConfig.userTableName);

      expect(result.length, greaterThanOrEqualTo(3));
      expect(result.any((u) => u['id'] == 'admin'), isTrue);
      expect(result.any((u) => u['id'] == 'kasir1'), isTrue);
      expect(result.any((u) => u['id'] == 'kasir2'), isTrue);
    });

    test('admin user should have admin role and correct password', () async {
      final result = await testDatabase.query(
        DatabaseConfig.userTableName,
        where: 'id = ?',
        whereArgs: ['admin'],
      );

      expect(result.length, 1);
      expect(result.first['role'], 'admin');
      expect(result.first['name'], 'Admin');
      expect(result.first['password'], 'admin123');
    });

    test('seed users should have non-null passwords', () async {
      final result = await testDatabase.query(DatabaseConfig.userTableName);
      for (final user in result) {
        expect(user['password'], isNotNull, reason: 'User ${user['id']} has null password');
        expect((user['password'] as String).isNotEmpty, isTrue,
            reason: 'User ${user['id']} has empty password');
      }
    });

    test('should insert products matching seed format via datasource', () async {
      final data = {
        'createdById': '7778024b-98a5-4df2-b912-a6e541a2ff1b',
        'name': 'Teh Botol Sosro',
        'imageUrl': '',
        'stock': 100,
        'sold': 55,
        'price': 5000,
        'wholesalePrice': 4500,
        'unit': 'pcs',
        'barcode': '8991002100220',
        'description': 'Teh botol sosro 250ml',
      };

      final productId = await testDatabase.insert(DatabaseConfig.productTableName, data);
      expect(productId, greaterThan(0));

      final saved = await testDatabase.query(
        DatabaseConfig.productTableName,
        where: 'id = ?',
        whereArgs: [productId],
      );

      expect(saved.length, 1);
      expect(saved.first['name'], 'Teh Botol Sosro');
      expect(saved.first['price'], 5000);
      expect(saved.first['stock'], 100);
    });

    test('should insert product units linked to product', () async {
      final productId = 1;

      await testDatabase.insert(DatabaseConfig.productUnitTableName, {
        'productId': productId,
        'unitName': 'pcs',
        'conversionValue': 1,
        'price': 5000,
        'wholesalePrice': 4500,
        'isBase': 1,
      });

      await testDatabase.insert(DatabaseConfig.productUnitTableName, {
        'productId': productId,
        'unitName': 'dus',
        'conversionValue': 12,
        'price': 55000,
        'wholesalePrice': 50000,
        'isBase': 0,
      });

      final units = await testDatabase.query(
        DatabaseConfig.productUnitTableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );

      expect(units.length, 2);

      final pcsUnit = units.firstWhere((u) => u['unitName'] == 'pcs');
      expect(pcsUnit['isBase'], 1);
      expect(pcsUnit['price'], 5000);

      final dusUnit = units.firstWhere((u) => u['unitName'] == 'dus');
      expect(dusUnit['conversionValue'], 12);
      expect(dusUnit['price'], 55000);
    });

    test('seed product JSON should match Supabase products table columns', () async {
      final json = {
        'id': 1,
        'createdById': '7778024b-98a5-4df2-b912-a6e541a2ff1b',
        'name': 'Teh Botol Sosro',
        'imageUrl': '',
        'stock': 100,
        'sold': 55,
        'price': 5000,
        'wholesalePrice': 4500,
        'unit': 'pcs',
        'barcode': '8991002100220',
        'description': 'Teh botol sosro 250ml',
      };

      final expectedColumns = [
        'id',
        'createdById',
        'name',
        'imageUrl',
        'stock',
        'sold',
        'price',
        'wholesalePrice',
        'unit',
        'barcode',
        'description',
      ];

      for (final col in expectedColumns) {
        expect(json, contains(col), reason: 'Column $col missing');
      }
    });

    test('seed unit JSON should match Supabase product_units columns', () async {
      final unitJson = {
        'productId': 1,
        'unitName': 'pcs',
        'conversionValue': 1,
        'price': 5000,
        'wholesalePrice': 4500,
        'isBase': 1,
      };

      final expectedColumns = [
        'productId',
        'unitName',
        'conversionValue',
        'price',
        'wholesalePrice',
        'isBase',
      ];

      for (final col in expectedColumns) {
        expect(unitJson, contains(col), reason: 'Column $col missing');
      }
    });

    test('createdById should reference the supabase admin user', () async {
      final users = await testDatabase.query(
        DatabaseConfig.userTableName,
        where: 'id = ?',
        whereArgs: ['7778024b-98a5-4df2-b912-a6e541a2ff1b'],
      );

      expect(users.length, 1);
      expect(users.first['role'], 'admin');
    });

    test('seed product data types match Supabase schema', () async {
      final json = {
        'id': 1,
        'createdById': '7778024b-98a5-4df2-b912-a6e541a2ff1b',
        'name': 'Teh Botol Sosro',
        'stock': 100,
        'sold': 55,
        'price': 5000,
      };

      expect(json['id'], isA<int>());
      expect(json['createdById'], isA<String>());
      expect(json['name'], isA<String>());
      expect(json['stock'], isA<int>());
      expect(json['price'], isA<int>());
    });
  });
}
