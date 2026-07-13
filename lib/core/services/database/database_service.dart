import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), DatabaseConfig.dbPath);

    database = await openDatabase(
      path,
      version: DatabaseConfig.version,
      onCreate: (db, version) async {
        await Future.wait([
          db.execute(DatabaseConfig.createUserTable),
          db.execute(DatabaseConfig.createProductTable),
          db.execute(DatabaseConfig.createProductUnitTable),
          db.execute(DatabaseConfig.createProductTieredPriceTable),
          db.execute(DatabaseConfig.createCustomerTable),
          db.execute(DatabaseConfig.createTransactionTable),
          db.execute(DatabaseConfig.createOrderedProductTable),
          db.execute(DatabaseConfig.createReceivablePaymentTable),
          db.execute(DatabaseConfig.createQueuedActionTable),
        ]);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _applyMigrations(db);
      },
    );

    await _applyMigrations(database);
    await _seedUsers(database);
    await _migrateLegacyProductUnits();
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

  Future<void> _seedUsers(Database db) async {
    // Migrate old 'local-user-id' to 'admin' if it exists
    final oldUser = await db.query(
      DatabaseConfig.userTableName,
      where: 'id = ?',
      whereArgs: ['local-user-id'],
    );
    if (oldUser.isNotEmpty) {
      await db.update(
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
        'id': '7778024b-98a5-4df2-b912-a6e541a2ff1b',
        'name': 'Admin',
        'email': 'admin@monopos.local',
        'authProvider': 'supabase',
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
      await db.insert(
        DatabaseConfig.userTableName,
        user,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Fix: ensure existing rows have correct password (handles pre-migration DBs
      // where password column was added via ALTER TABLE and is NULL/empty for existing rows)
      await db.rawUpdate(
        "UPDATE '${DatabaseConfig.userTableName}' SET password = ? WHERE id = ? AND (password IS NULL OR password = '')",
        [user['password'], user['id']],
      );
    }
  }

  Future<void> _applyMigrations(Database db) async {
    // Migration: add wholesalePrice column
    await _addColumnIfNotExists(db, 'Product', 'wholesalePrice', 'INTEGER');

    // Migration: add priceType column
    await _addColumnIfNotExists(db, 'OrderedProduct', 'priceType', "TEXT DEFAULT 'retail'");

    // Migration: add unit column to Product
    await _addColumnIfNotExists(db, 'Product', 'unit', "TEXT DEFAULT 'pcs'");

    // Migration: add barcode column
    await _addColumnIfNotExists(db, 'Product', 'barcode', 'TEXT');

    // Migration: add unit column to OrderedProduct
    await _addColumnIfNotExists(db, 'OrderedProduct', 'unit', "TEXT DEFAULT 'pcs'");

    // Migration: add conversionValue column to OrderedProduct
    await _addColumnIfNotExists(db, 'OrderedProduct', 'conversionValue', 'INTEGER NOT NULL DEFAULT 1');

    // Migration: add password column to User
    await _addColumnIfNotExists(db, 'User', 'password', 'TEXT');

    // Migration: add role column to User
    await _addColumnIfNotExists(db, 'User', 'role', "TEXT DEFAULT 'kasir'");

    // Migration: add columns to Transaction (check existence first)
    await _addColumnIfNotExists(db, 'Transaction', 'paymentStatus', "TEXT DEFAULT 'paid'");
    await _addColumnIfNotExists(db, 'Transaction', 'paymentQR', 'TEXT');
    await _addColumnIfNotExists(db, 'Transaction', 'paymentExternalId', 'TEXT');

    // Migration: create tiered price table
    try {
      await db.execute(DatabaseConfig.createProductTieredPriceTable);
    } catch (_) {}

    // Migration: create customer table
    try {
      await db.execute(DatabaseConfig.createCustomerTable);
    } catch (_) {}

    // Migration: add paymentType column to Transaction
    await _addColumnIfNotExists(db, 'Transaction', 'paymentType', "TEXT DEFAULT 'cash'");

    // Migration: add customerId column to Transaction
    await _addColumnIfNotExists(db, 'Transaction', 'customerId', 'TEXT');

    // Migration: add dueDate column to Transaction
    await _addColumnIfNotExists(db, 'Transaction', 'dueDate', 'TEXT');

    // Migration: create receivable payment table
    try {
      await db.execute(DatabaseConfig.createReceivablePaymentTable);
    } catch (_) {}
  }

  Future<void> _seedProducts() async {
    if (!kDebugMode) return;

    final seedUserIds = ['admin', '7778024b-98a5-4df2-b912-a6e541a2ff1b', 'kasir1', 'kasir2'];

    final products = <(String, int, int, String, int, int, String, int?, int?)>[
      ('Teh Botol Sosro', 5000, 4500, '8991002100220', 100, 55, 'Teh botol sosro 250ml', 55000, 50000),
      ('Indomie Goreng', 3500, 3200, '8991002100221', 200, 9, 'Indomie goreng original 85g', 31000, 28000),
      ('Coca Cola', 7000, 6500, '8991002100222', 80, 3, 'Coca cola 390ml kaleng', 81000, 75000),
      ('Aqua', 3000, 2500, '8991002100223', 150, 5, 'Air mineral aqua 600ml', 35000, 29000),
      ('Minyak Goreng Sania', 15000, 14000, '8991002100224', 50, 4, 'Minyak goreng sania 1L', 175000, 160000),
      ('Beras Ramos', 75000, 72000, '8991002100225', 30, 0, 'Beras ramos 5kg premium', null, null),
      ('Gula Pasir Gulaku', 14000, 13000, '8991002100226', 60, 2, 'Gula pasir gulaku 1kg', 165000, 150000),
      ('Telur Ayam', 2500, 2300, '8991002100227', 500, 0, 'Telur ayam negeri per butir', null, null),
      ('Susu Kental Manis', 12000, 11000, '8991002100228', 90, 1, 'Frisian flag susu kental manis', 140000, 128000),
      ('Kopi Kapal Api', 17000, 16000, '8991002100229', 70, 6, 'Kopi kapal api 10 sachet', 200000, 185000),
      ('Sabun Mandi Lifebuoy', 4500, 4000, '8991002100230', 120, 8, 'Sabun mandi lifebuoy 90g', 52000, 47000),
      ('Shampoo Pantene', 2000, 1700, '8991002100231', 200, 12, 'Shampoo pantene sachet 3ml', null, null),
      ('Kecap Manis ABC', 8000, 7200, '8991002100232', 90, 3, 'Kecap manis abc 135ml', 95000, 86000),
      ('Saos Sambal ABC', 8500, 7800, '8991002100233', 85, 5, 'Saos sambal abc 140ml', 100000, 92000),
      (
        'Tepung Terigu Segitiga Biru',
        13000,
        12000,
        '8991002100234',
        45,
        2,
        'Tepung terigu segitiga biru 1kg',
        null,
        null,
      ),
    ];

    for (final userId in seedUserIds) {
      try {
        final existing = await database.query(
          DatabaseConfig.productTableName,
          where: 'createdById = ?',
          whereArgs: [userId],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;

        for (final p in products) {
          final productId = await database.insert(
            DatabaseConfig.productTableName,
            {
              'createdById': userId,
              'name': p.$1,
              'imageUrl': '',
              'stock': p.$5,
              'sold': p.$6,
              'price': p.$2,
              'wholesalePrice': p.$3,
              'unit': 'pcs',
              'barcode': p.$4,
              'description': p.$7,
            },
          );

          await database.insert(DatabaseConfig.productUnitTableName, {
            'productId': productId,
            'unitName': 'pcs',
            'conversionValue': 1,
            'price': p.$2,
            'wholesalePrice': p.$3,
            'isBase': 1,
          });

          if (p.$8 != null) {
            await database.insert(DatabaseConfig.productUnitTableName, {
              'productId': productId,
              'unitName': 'dus',
              'conversionValue': 12,
              'price': p.$8,
              'wholesalePrice': p.$9,
              'isBase': 0,
            });
          }
        }

        cw('Seeded ${products.length} products for user: $userId');
      } catch (e) {
        ce('Seed products for $userId failed: $e');
      }
    }
  }

  @visibleForTesting
  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info('$table')");
      final exists = result.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute("ALTER TABLE '$table' ADD COLUMN '$column' $type");
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
      database.execute(DatabaseConfig.createProductTieredPriceTable),
      database.execute(DatabaseConfig.createCustomerTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createReceivablePaymentTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
    ]);

    await _seedUsers(database);
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
