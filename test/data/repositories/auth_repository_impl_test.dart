import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/data/datasources/interfaces/auth_datasource.dart';
import 'package:mono_pos/data/datasources/local/auth_local_datasource_impl.dart';
import 'package:mono_pos/data/models/user_model.dart';
import 'package:mono_pos/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([
  AuthLocalDataSourceImpl,
  AuthDataSource,
])
void main() {
  late AuthRepositoryImpl repository;
  late MockAuthLocalDataSourceImpl mockLocalDatasource;
  late MockAuthDataSource mockRemoteDatasource;

  setUp(() {
    mockLocalDatasource = MockAuthLocalDataSourceImpl();
    mockRemoteDatasource = MockAuthDataSource();

    provideDummy<Result<UserModel>>(
      Result.success(data: UserModel(id: '')),
    );
    provideDummy<Result<UserModel?>>(
      Result.success(data: null),
    );
    provideDummy<Result<void>>(
      Result.success(data: null),
    );

    repository = AuthRepositoryImpl(
      authLocalDataSource: mockLocalDatasource,
      authRemoteDataSource: mockRemoteDatasource,
    );
  });

  group('signInWithGoogle', () {
    test('returns UserEntity on successful remote sign in', () async {
      final userModel = UserModel(id: 'google123', name: 'Google User', email: 'google@example.com');

      when(mockRemoteDatasource.signInWithGoogle()).thenAnswer((_) async => Result.success(data: userModel));

      final result = await repository.signInWithGoogle();

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Google User');
      verify(mockRemoteDatasource.signInWithGoogle()).called(1);
      verifyNever(mockLocalDatasource.signInWithGoogle());
    });

    test('falls back to local when remote fails', () async {
      final userModel = UserModel(id: 'local123', name: 'Local User', email: 'local@example.com');

      when(mockRemoteDatasource.signInWithGoogle()).thenAnswer((_) async => Result.failure(error: 'Network error'));
      when(mockLocalDatasource.signInWithGoogle()).thenAnswer((_) async => Result.success(data: userModel));

      final result = await repository.signInWithGoogle();

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Local User');
      verify(mockRemoteDatasource.signInWithGoogle()).called(1);
      verify(mockLocalDatasource.signInWithGoogle()).called(1);
    });

    test('returns failure when both remote and local fail', () async {
      when(mockRemoteDatasource.signInWithGoogle()).thenAnswer((_) async => Result.failure(error: 'Remote error'));
      when(mockLocalDatasource.signInWithGoogle()).thenAnswer((_) async => Result.failure(error: 'Local error'));

      final result = await repository.signInWithGoogle();

      expect(result.isFailure, true);
    });
  });

  group('signInWithEmailPassword', () {
    test('returns UserEntity on successful remote sign in', () async {
      final userModel = UserModel(id: 'user123', name: 'User', email: 'user@example.com');

      when(
        mockRemoteDatasource.signInWithEmailPassword(username: 'test', password: 'pass'),
      ).thenAnswer((_) async => Result.success(data: userModel));

      final result = await repository.signInWithEmailPassword(username: 'test', password: 'pass');

      expect(result.isSuccess, true);
      expect(result.data!.name, 'User');
    });

    test('falls back to local when remote fails', () async {
      final userModel = UserModel(id: 'local123', name: 'Local', email: 'local@example.com');

      when(
        mockRemoteDatasource.signInWithEmailPassword(username: 'test', password: 'pass'),
      ).thenAnswer((_) async => Result.failure(error: 'Invalid credentials'));
      when(
        mockLocalDatasource.signInWithEmailPassword(username: 'test', password: 'pass'),
      ).thenAnswer((_) async => Result.success(data: userModel));

      final result = await repository.signInWithEmailPassword(username: 'test', password: 'pass');

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Local');
    });
  });

  group('signOut', () {
    test('signs out of both remote and local', () async {
      when(mockRemoteDatasource.signOut()).thenAnswer((_) async => Result.success(data: null));
      when(mockLocalDatasource.signOut()).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.signOut();

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.signOut()).called(1);
      verify(mockLocalDatasource.signOut()).called(1);
    });

    test('returns failure when local sign out fails', () async {
      when(mockRemoteDatasource.signOut()).thenAnswer((_) async => Result.success(data: null));
      when(mockLocalDatasource.signOut()).thenAnswer((_) async => Result.failure(error: 'Sign out failed'));

      final result = await repository.signOut();

      expect(result.isFailure, true);
      expect(result.error, 'Sign out failed');
    });
  });

  group('getCurrentUser', () {
    test('returns remote user when available', () async {
      final userModel = UserModel(id: 'remote123', name: 'Remote', email: 'remote@example.com');

      when(mockRemoteDatasource.getCurrentUser()).thenAnswer((_) async => Result.success(data: userModel));

      final result = await repository.getCurrentUser();

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Remote');
      verifyNever(mockLocalDatasource.getCurrentUser());
    });

    test('falls back to local when remote returns null', () async {
      final userModel = UserModel(id: 'local123', name: 'Local', email: 'local@example.com');

      when(mockRemoteDatasource.getCurrentUser()).thenAnswer((_) async => Result.success(data: null));
      when(mockLocalDatasource.getCurrentUser()).thenAnswer((_) async => Result.success(data: userModel));

      final result = await repository.getCurrentUser();

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Local');
    });

    test('returns null when no user is logged in', () async {
      when(mockRemoteDatasource.getCurrentUser()).thenAnswer((_) async => Result.success(data: null));
      when(mockLocalDatasource.getCurrentUser()).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.getCurrentUser();

      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });
  });
}
