import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/data/datasources/local/queued_action_local_datasource_impl.dart';
import 'package:mono_pos/data/models/queued_action_model.dart';
import 'package:mono_pos/data/repositories/queued_action_repository_impl.dart';
import 'package:mono_pos/domain/entities/queued_action_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'queued_action_repository_impl_test.mocks.dart';

@GenerateMocks([
  QueuedActionLocalDatasourceImpl,
])
void main() {
  late QueuedActionRepositoryImpl repository;
  late MockQueuedActionLocalDatasourceImpl mockDatasource;

  setUp(() {
    mockDatasource = MockQueuedActionLocalDatasourceImpl();

    provideDummy<Result<List<QueuedActionModel>>>(
      Result.success(data: <QueuedActionModel>[]),
    );
    provideDummy<Result<QueuedActionModel?>>(
      Result.success(data: null),
    );
    provideDummy<Result<int>>(
      Result.success(data: 0),
    );
    provideDummy<Result<void>>(
      Result.success(data: null),
    );

    repository = QueuedActionRepositoryImpl(localDatasource: mockDatasource);
  });

  group('createQueuedAction', () {
    final action = QueuedActionEntity(
      id: null,
      repository: 'product',
      method: 'createProduct',
      param: '{}',
      isCritical: false,
      createdAt: '2025-01-01T10:00:00Z',
    );

    test('creates queued action successfully', () async {
      when(mockDatasource.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createQueuedAction(action);

      expect(result.isSuccess, true);
      expect(result.data, 1);
      verify(mockDatasource.createQueuedAction(any)).called(1);
    });

    test('returns failure when datasource fails', () async {
      when(mockDatasource.createQueuedAction(any)).thenAnswer((_) async => Result.failure(error: 'DB error'));

      final result = await repository.createQueuedAction(action);

      expect(result.isFailure, true);
      expect(result.error, 'DB error');
    });
  });

  group('getAllQueuedActions', () {
    test('returns list of queued actions on success', () async {
      final actions = [
        QueuedActionModel(
          id: 1,
          repository: 'product',
          method: 'createProduct',
          param: '{}',
          isCritical: true,
          createdAt: '2025-01-01T10:00:00Z',
        ),
      ];

      when(mockDatasource.getAllUserQueuedAction()).thenAnswer((_) async => Result.success(data: actions));

      final result = await repository.getAllQueuedActions();

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data!.first.repository, 'product');
    });

    test('returns empty list when no actions queued', () async {
      when(mockDatasource.getAllUserQueuedAction()).thenAnswer((_) async => Result.success(data: []));

      final result = await repository.getAllQueuedActions();

      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('returns failure when datasource fails', () async {
      when(mockDatasource.getAllUserQueuedAction()).thenAnswer((_) async => Result.failure(error: 'DB error'));

      final result = await repository.getAllQueuedActions();

      expect(result.isFailure, true);
      expect(result.error, 'DB error');
    });
  });

  group('deleteQueuedAction', () {
    test('deletes queued action successfully', () async {
      when(mockDatasource.deleteQueuedAction(1)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.deleteQueuedAction(1);

      expect(result.isSuccess, true);
      verify(mockDatasource.deleteQueuedAction(1)).called(1);
    });

    test('returns failure when datasource fails', () async {
      when(mockDatasource.deleteQueuedAction(1)).thenAnswer((_) async => Result.failure(error: 'Delete failed'));

      final result = await repository.deleteQueuedAction(1);

      expect(result.isFailure, true);
      expect(result.error, 'Delete failed');
    });
  });
}
