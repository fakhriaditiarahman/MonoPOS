import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/core/services/database/database_config.dart';
import 'package:mono_pos/core/services/database/database_service.dart';
import 'package:mono_pos/data/datasources/local/auth_local_datasource_impl.dart';
import 'package:mono_pos/data/datasources/local/user_local_datasource_impl.dart';
import 'package:mono_pos/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService appDatabase;
  late Database testDatabase;
  late UserLocalDatasourceImpl userLocalDatasource;
  late AuthLocalDataSourceImpl authLocalDatasource;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    testDatabase = await openDatabase(inMemoryDatabasePath, version: 1);

    appDatabase = DatabaseService.instance;
    await appDatabase.initTestDatabase(testDatabase: testDatabase);

    userLocalDatasource = UserLocalDatasourceImpl(appDatabase);
    authLocalDatasource = AuthLocalDataSourceImpl(userLocalDatasource);
  });

  tearDownAll(() async {
    await testDatabase.close();
  });

  group('AuthLocalDataSourceImpl', () {
    group('signInWithEmailPassword', () {
      test('should return user when password matches for admin', () async {
        final result = await authLocalDatasource.signInWithEmailPassword(
          username: 'admin',
          password: 'admin123',
        );

        expect(result.isSuccess, true);
        expect(result.data!.id, 'admin');
        expect(result.data!.role, 'admin');
      });

      test('should return user when password matches for kasir1', () async {
        final result = await authLocalDatasource.signInWithEmailPassword(
          username: 'kasir1',
          password: 'kasir123',
        );

        expect(result.isSuccess, true);
        expect(result.data!.id, 'kasir1');
        expect(result.data!.role, 'kasir');
      });

      test('should return failure when password is wrong', () async {
        final result = await authLocalDatasource.signInWithEmailPassword(
          username: 'admin',
          password: 'wrongpassword',
        );

        expect(result.isFailure, true);
        expect(result.error, 'Username atau password salah!');
      });

      test('should return failure when username does not exist', () async {
        final result = await authLocalDatasource.signInWithEmailPassword(
          username: 'nonexistent',
          password: 'anypassword',
        );

        expect(result.isFailure, true);
        expect(result.error, 'Username atau password salah!');
      });

      test('should return failure when password is null in database', () async {
        await testDatabase.update(
          DatabaseConfig.userTableName,
          {'password': null},
          where: 'id = ?',
          whereArgs: ['admin'],
        );

        final result = await authLocalDatasource.signInWithEmailPassword(
          username: 'admin',
          password: 'admin123',
        );

        expect(result.isFailure, true);
        expect(result.error, 'Username atau password salah!');

        await testDatabase.update(
          DatabaseConfig.userTableName,
          {'password': 'admin123'},
          where: 'id = ?',
          whereArgs: ['admin'],
        );
      });

      test('should return failure when password is empty string in database', () async {
        await testDatabase.update(
          DatabaseConfig.userTableName,
          {'password': ''},
          where: 'id = ?',
          whereArgs: ['admin'],
        );

        final result = await authLocalDatasource.signInWithEmailPassword(
          username: 'admin',
          password: 'admin123',
        );

        expect(result.isFailure, true);
        expect(result.error, 'Username atau password salah!');

        await testDatabase.update(
          DatabaseConfig.userTableName,
          {'password': 'admin123'},
          where: 'id = ?',
          whereArgs: ['admin'],
        );
      });
    });

    group('signInWithGoogle', () {
      test('should return local admin user', () async {
        final result = await authLocalDatasource.signInWithGoogle();

        expect(result.isSuccess, true);
        expect(result.data!.id, 'local-user-id');
        expect(result.data!.name, 'Admin');
      });
    });

    group('signOut', () {
      test('should return success', () async {
        final result = await authLocalDatasource.signOut();

        expect(result.isSuccess, true);
      });
    });

    group('getCurrentUser', () {
      test('should return null (not implemented for local)', () async {
        final result = await authLocalDatasource.getCurrentUser();

        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });
    });
  });

  group('UserLocalDatasourceImpl - getUserByUsername', () {
    test('should find admin user by username', () async {
      final result = await userLocalDatasource.getUserByUsername('admin');

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.id, 'admin');
      expect(result.data!.password, 'admin123');
    });

    test('should return null for non-existent username', () async {
      final result = await userLocalDatasource.getUserByUsername('nonexistent');

      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });

    test('should find kasir1 user by username', () async {
      final result = await userLocalDatasource.getUserByUsername('kasir1');

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.id, 'kasir1');
      expect(result.data!.password, 'kasir123');
    });
  });
}
