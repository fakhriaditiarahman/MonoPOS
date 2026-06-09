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
      // Initialize FFI
      sqfliteFfiInit();
    }

    // Get the path to the database
    String path = join(await getDatabasesPath(), DatabaseConfig.dbPath);

    if (kDebugMode) {
      // Only for development purpose
      // await dropDatabase(path);
    }

    // Create database if not exists
    File databaseFile = File(path);

    if (!await databaseFile.exists()) await databaseFile.create();

    // Open database
    database = await openDatabase(path);

    // Create tables
    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
    ]);

    // Migration: add wholesalePrice column (safe for existing DBs)
    try {
      await database.execute('ALTER TABLE Product ADD COLUMN wholesalePrice INTEGER');
    } catch (_) {}

    // Migration: add priceType column
    try {
      await database.execute("ALTER TABLE OrderedProduct ADD COLUMN priceType TEXT DEFAULT 'retail'");
    } catch (_) {}

    // Migration: add unit column
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
  }

  @visibleForTesting
  Future<void> initTestDatabase({required Database testDatabase}) async {
    database = testDatabase;

    // Create tables
    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
    ]);
  }

  Future<void> dropDatabase(String path) async {
    // Check if the database file exists
    File databaseFile = File(path);

    if (await databaseFile.exists()) {
      // Delete the database file
      await databaseFile.delete();

      cw('Database deleted successfully!');
    } else {
      ce('Database does not exist!');
    }
  }
}
