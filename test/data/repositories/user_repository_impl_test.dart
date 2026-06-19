import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/core/services/sync/sync_service.dart';
import 'package:mono_pos/data/datasources/interfaces/user_datasource.dart';
import 'package:mono_pos/data/datasources/local/user_local_datasource_impl.dart';
import 'package:mono_pos/data/models/user_model.dart';
import 'package:mono_pos/data/repositories/user_repository_impl.dart';
import 'package:mono_pos/domain/entities/user_entity.dart';
import 'package:mono_pos/domain/repositories/queued_action_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([
  SyncService,
  UserLocalDatasourceImpl,
  UserDatasource,
  QueuedActionRepository,
])
void main() {
  late UserRepositoryImpl repository;
  late MockSyncService mockSyncService;
  late MockUserLocalDatasourceImpl mockLocalDatasource;
  late MockUserDatasource mockRemoteDatasource;
  late MockQueuedActionRepository mockQueuedActionRepository;

  setUp(() {
    mockSyncService = MockSyncService();
    mockLocalDatasource = MockUserLocalDatasourceImpl();
    mockRemoteDatasource = MockUserDatasource();
    mockQueuedActionRepository = MockQueuedActionRepository();

    provideDummy<Result<UserModel?>>(
      Result.success(
        data: UserModel(id: ''),
      ),
    );
    provideDummy<Result<String>>(
      Result.success(data: ''),
    );
    provideDummy<Result<void>>(
      Result.success(data: null),
    );
    provideDummy<Result<int>>(
      Result.success(data: 0),
    );

    repository = UserRepositoryImpl(
      userLocalDatasource: mockLocalDatasource,
      userRemoteDatasource: mockRemoteDatasource,
      syncService: mockSyncService,
      queuedActionRepository: mockQueuedActionRepository,
    );
  });

  group('getUser', () {
    const userId = 'user123';
    final localUser = UserModel(
      id: userId,
      name: 'Local User',
      email: 'local@example.com',
      phone: '1234567890',
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('returns local user on success', () async {
      when(mockLocalDatasource.getUser(userId)).thenAnswer((_) async => Result.success(data: localUser));

      final result = await repository.getUser(userId);

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Local User');
      verify(mockLocalDatasource.getUser(userId)).called(1);
    });

    test('returns null when user not found locally', () async {
      when(mockLocalDatasource.getUser(userId)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.getUser(userId);

      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });

    test('returns failure when local datasource fails', () async {
      when(mockLocalDatasource.getUser(userId)).thenAnswer((_) async => Result.failure(error: 'User not found'));

      final result = await repository.getUser(userId);

      expect(result.isFailure, true);
      expect(result.error, 'User not found');
    });

    test('handles exception', () async {
      when(mockLocalDatasource.getUser(userId)).thenThrow(Exception('Unexpected error'));

      final result = await repository.getUser(userId);

      expect(result.isFailure, true);
    });
  });

  group('getUserByUsername', () {
    const username = 'testuser';
    final localUser = UserModel(
      id: 'user123',
      name: 'Test User',
      email: 'test@example.com',
      phone: '1234567890',
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('returns local user on success', () async {
      when(mockLocalDatasource.getUserByUsername(username)).thenAnswer((_) async => Result.success(data: localUser));

      final result = await repository.getUserByUsername(username);

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Test User');
      verify(mockLocalDatasource.getUserByUsername(username)).called(1);
    });

    test('returns null when user not found', () async {
      when(mockLocalDatasource.getUserByUsername(username)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.getUserByUsername(username);

      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });

    test('returns failure when local datasource fails', () async {
      when(mockLocalDatasource.getUserByUsername(username)).thenAnswer((_) async => Result.failure(error: 'DB error'));

      final result = await repository.getUserByUsername(username);

      expect(result.isFailure, true);
      expect(result.error, 'DB error');
    });
  });

  group('createUser', () {
    final user = UserEntity(
      id: 'user123',
      name: 'New User',
      email: 'new@example.com',
      phone: '1234567890',
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('creates user locally and syncs remote when online', () async {
      const generatedId = 'generated123';

      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createUser(any)).thenAnswer((_) async => Result.success(data: generatedId));
      when(mockRemoteDatasource.createUser(any)).thenAnswer((_) async => Result.success(data: generatedId));

      final result = await repository.createUser(user);

      expect(result.isSuccess, true);
      expect(result.data, generatedId);
      verify(mockLocalDatasource.createUser(any)).called(1);
      verify(mockRemoteDatasource.createUser(any)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('creates user locally and queues action when offline', () async {
      const generatedId = 'generated456';

      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.createUser(any)).thenAnswer((_) async => Result.success(data: generatedId));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createUser(user);

      expect(result.isSuccess, true);
      expect(result.data, generatedId);
      verify(mockLocalDatasource.createUser(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.createUser(any));
    });

    test('queues action when remote call fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createUser(any)).thenAnswer((_) async => Result.success(data: 'user123'));
      when(mockRemoteDatasource.createUser(any)).thenAnswer((_) async => Result.failure(error: 'Server error'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createUser(user);

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.createUser(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
    });

    test('returns failure when local creation fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createUser(any)).thenAnswer((_) async => Result.failure(error: 'Database error'));

      final result = await repository.createUser(user);

      expect(result.isFailure, true);
      expect(result.error, 'Database error');
      verifyNever(mockRemoteDatasource.createUser(any));
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('sets correct queued action structure', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.createUser(any)).thenAnswer((_) async => Result.success(data: 'user123'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      await repository.createUser(user);

      final captured = verify(mockQueuedActionRepository.createQueuedAction(captureAny)).captured.single;
      expect((captured as dynamic).repository, 'user');
      expect((captured as dynamic).method, 'createUser');
      expect((captured as dynamic).isCritical, false);
    });
  });

  group('updateUser', () {
    final user = UserEntity(
      id: 'user123',
      name: 'Updated User',
      email: 'updated@example.com',
      phone: '9876543210',
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T12:00:00Z',
    );

    test('updates user locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateUser(any)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.updateUser(any)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.updateUser(user);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updateUser(any)).called(1);
      verify(mockRemoteDatasource.updateUser(any)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('updates user locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.updateUser(any)).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.updateUser(user);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updateUser(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.updateUser(any));
    });

    test('returns failure when local update fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateUser(any)).thenAnswer((_) async => Result.failure(error: 'Update failed'));

      final result = await repository.updateUser(user);

      expect(result.isFailure, true);
      expect(result.error, 'Update failed');
    });

    test('handles exception', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateUser(any)).thenThrow(Exception('Unexpected error'));

      final result = await repository.updateUser(user);

      expect(result.isFailure, true);
    });
  });

  group('deleteUser', () {
    const userId = 'user123';

    test('deletes user locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.deleteUser(userId)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.deleteUser(userId)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.deleteUser(userId);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.deleteUser(userId)).called(1);
      verify(mockRemoteDatasource.deleteUser(userId)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('deletes user locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.deleteUser(userId)).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.deleteUser(userId);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.deleteUser(userId)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.deleteUser(userId));
    });

    test('returns failure when local deletion fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.deleteUser(userId)).thenAnswer((_) async => Result.failure(error: 'Delete failed'));

      final result = await repository.deleteUser(userId);

      expect(result.isFailure, true);
      expect(result.error, 'Delete failed');
    });

    test('handles exception', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.deleteUser(userId)).thenThrow(Exception('Unexpected error'));

      final result = await repository.deleteUser(userId);

      expect(result.isFailure, true);
    });
  });

  group('_syncRemote edge cases', () {
    test('queues action when remote call throws exception', () async {
      const userId = 'user123';
      final user = UserEntity(
        id: userId,
        name: 'Test',
        email: 'test@example.com',
        phone: '1234567890',
      );

      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createUser(any)).thenAnswer((_) async => Result.success(data: userId));
      when(mockRemoteDatasource.createUser(any)).thenThrow(Exception('Network error'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createUser(user);

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.createUser(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
    });
  });
}
