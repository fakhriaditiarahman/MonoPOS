import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../utilities/console_logger.dart';
import 'database_config.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  static DatabaseService get instance => _instance;

  late Database database;

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }

    String path = join(await getDatabasesPath(), DatabaseConfig.dbPath);

    if (kDebugMode) {
      // await dropDatabase(path);
    }

    File databaseFile = File(path);

    if (!await databaseFile.exists()) await databaseFile.create();

    database = await openDatabase(path);

    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createProductUnitTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
    ]);

    // Migration: add wholesalePrice column
    try {
      await database.execute('ALTER TABLE Product ADD COLUMN wholesalePrice INTEGER');
    } catch (_) {}

    // Migration: add priceType column
    try {
      await database.execute("ALTER TABLE OrderedProduct ADD COLUMN priceType TEXT DEFAULT 'retail'");
    } catch (_) {}

    // Migration: add unit column to Product
    try {
      await database.execute("ALTER TABLE Product ADD COLUMN unit TEXT DEFAULT 'pcs'");
    } catch (_) {}

    // Migration: add barcode column
    try {
      await database.execute('ALTER TABLE Product ADD COLUMN barcode TEXT');
    } catch (_) {}

    // Migration: add unit column to OrderedProduct
    try {
      await database.execute("ALTER TABLE OrderedProduct ADD COLUMN unit TEXT DEFAULT 'pcs'");
    } catch (_) {}

    // Migration: add conversionValue column to OrderedProduct
    try {
      await database.execute('ALTER TABLE OrderedProduct ADD COLUMN conversionValue INTEGER NOT NULL DEFAULT 1');
    } catch (_) {}

    // Migration: add password column to User
    try {
      await database.execute("ALTER TABLE User ADD COLUMN password TEXT");
    } catch (_) {}

    // Migration: add role column to User
    try {
      await database.execute("ALTER TABLE User ADD COLUMN role TEXT DEFAULT 'kasir'");
    } catch (_) {}

    // Migration: add columns to Transaction (check existence first)
    await _addColumnIfNotExists('Transaction', 'paymentStatus', "TEXT DEFAULT 'paid'");
    await _addColumnIfNotExists('Transaction', 'paymentQR', 'TEXT');
    await _addColumnIfNotExists('Transaction', 'paymentExternalId', 'TEXT');

    // Seed initial users
    await _seedUsers();

    // Migrate legacy products (create ProductUnit rows for products without units)
    await _migrateLegacyProductUnits();

    // Seed sample products for development
    await _seedProducts();
  }

  Future<void> _migrateLegacyProductUnits() async {
    try {
      // Find all products that don't have any units in ProductUnit table
      final legacyProducts = await database.rawQuery('''
        SELECT p.id, p.unit, p.price, p.wholesalePrice 
        FROM Product p 
        WHERE p.id NOT IN (SELECT DISTINCT productId FROM ProductUnit)
      ''');

      if (legacyProducts.isNotEmpty) {
        // Insert a single ProductUnit row for each legacy product
        for (final product in legacyProducts) {
          await database.insert(
            DatabaseConfig.productUnitTableName,
            {
              'productId': product['id'],
              'unitName': product['unit'] ?? 'pcs',
              'conversionValue': 1,
              'price': product['price'] ?? 0,
              'wholesalePrice': product['wholesalePrice'],
              'isBase': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        cw('Migrated ${legacyProducts.length} legacy products to new unit system');
      }
    } catch (e) {
      ce('Migration failed: $e');
    }
  }

  Future<void> _seedUsers() async {
    // Migrate old 'local-user-id' to 'admin' if it exists
    final oldUser = await database.query(
      DatabaseConfig.userTableName,
      where: 'id = ?',
      whereArgs: ['local-user-id'],
    );
    if (oldUser.isNotEmpty) {
      await database.update(
        DatabaseConfig.userTableName,
        {
          'id': 'admin',
          'name': 'Admin',
          'password': 'admin123',
          'role': 'admin',
          'authProvider': 'local',
        },
        where: 'id = ?',
        whereArgs: ['local-user-id'],
      );
    }

    // Seed missing users (INSERT OR IGNORE)
    final seedUsers = [
      {
        'id': 'admin',
        'name': 'Admin',
        'email': 'admin@localhost',
        'authProvider': 'local',
        'password': 'admin123',
        'role': 'admin',
      },
      {
        'id': 'kasir1',
        'name': 'Kasir 1',
        'email': 'kasir1@localhost',
        'authProvider': 'local',
        'password': 'kasir123',
        'role': 'kasir',
      },
      {
        'id': 'kasir2',
        'name': 'Kasir 2',
        'email': 'kasir2@localhost',
        'authProvider': 'local',
        'password': 'kasir123',
        'role': 'kasir',
      },
    ];

    for (final user in seedUsers) {
      await database.insert(
        DatabaseConfig.userTableName,
        user,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _seedProducts() async {
    if (!kDebugMode) return;

    try {
      // Check if seed products already exist (by barcode)
      final existing = await database.query(
        DatabaseConfig.productTableName,
        where: 'barcode = ?',
        whereArgs: ['8991002100220'],
      );

      if (existing.isNotEmpty) return;

      // Insert product
      final productId = await database.insert(
        DatabaseConfig.productTableName,
        {
          'createdById': 'admin',
          'name': 'Teh Botol Sosro',
          'imageUrl': '',
          'stock': 100,
          'sold': 0,
          'price': 5000,
          'wholesalePrice': 4500,
          'unit': 'pcs',
          'barcode': '8991002100220',
          'description': 'Teh botol sosro 250ml',
        },
      );

      // Insert base unit (pcs)
      await database.insert(
        DatabaseConfig.productUnitTableName,
        {
          'productId': productId,
          'unitName': 'pcs',
          'conversionValue': 1,
          'price': 5000,
          'wholesalePrice': 4500,
          'isBase': 1,
        },
      );

      // Insert dus unit (12 pcs per dus)
      await database.insert(
        DatabaseConfig.productUnitTableName,
        {
          'productId': productId,
          'unitName': 'dus',
          'conversionValue': 12,
          'price': 55000,
          'wholesalePrice': 50000,
          'isBase': 0,
        },
      );

      cw('Seeded sample product: Teh Botol Sosro');
    } catch (e) {
      ce('Seed products failed: $e');
    }
  }

  @visibleForTesting
  Future<void> _addColumnIfNotExists(String table, String column, String type) async {
    try {
      final result = await database.rawQuery("PRAGMA table_info('$table')");
      final exists = result.any((row) => row['name'] == column);
      if (!exists) {
        await database.execute("ALTER TABLE '$table' ADD COLUMN '$column' $type");
        cw('Added column $column to $table');
      }
    } catch (e) {
      ce('Migration add column $column failed: $e');
    }
  }

  Future<void> initTestDatabase({required Database testDatabase}) async {
    database = testDatabase;

    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createProductUnitTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
    ]);

    await _seedUsers();
  }

  Future<void> dropDatabase(String path) async {
    File databaseFile = File(path);

    if (await databaseFile.exists()) {
      await databaseFile.delete();
      cw('Database deleted successfully!');
    } else {
      ce('Database does not exist!');
    }
  }
}
