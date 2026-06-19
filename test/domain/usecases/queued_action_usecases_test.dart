import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/domain/entities/queued_action_entity.dart';
import 'package:mono_pos/domain/repositories/queued_action_repository.dart';
import 'package:mono_pos/domain/usecases/params/no_param.dart';
import 'package:mono_pos/domain/usecases/queued_action_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'queued_action_usecases_test.mocks.dart';

@GenerateMocks([QueuedActionRepository])
void main() {
  late MockQueuedActionRepository mockQueuedActionRepository;

  setUpAll(() {
    provideDummy<Result<List<QueuedActionEntity>>>(
      Result<List<QueuedActionEntity>>.success(data: []),
    );
    provideDummy<Result<int>>(
      Result<int>.success(data: 0),
    );
    provideDummy<Result<void>>(
      Result<void>.success(data: null),
    );
  });

  setUp(() {
    mockQueuedActionRepository = MockQueuedActionRepository();
  });

  group('CreateQueuedActionUsecase', () {
    late CreateQueuedActionUsecase usecase;

    setUp(() {
      usecase = CreateQueuedActionUsecase(mockQueuedActionRepository);
    });

    test('should create queued action successfully', () async {
      final action = QueuedActionEntity(
        id: null,
        repository: 'product',
        method: 'createProduct',
        param: '{}',
        isCritical: false,
      );
      final result = Result<int>.success(data: 1);

      when(mockQueuedActionRepository.createQueuedAction(action)).thenAnswer((_) async => result);

      final response = await usecase.call(action);

      expect(response, result);
      expect(response.data, 1);
      verify(mockQueuedActionRepository.createQueuedAction(action));
      verifyNoMoreInteractions(mockQueuedActionRepository);
    });

    test('should return failure when creation fails', () async {
      final action = QueuedActionEntity(
        id: null,
        repository: 'product',
        method: 'createProduct',
        param: '{}',
        isCritical: false,
      );
      final result = Result<int>.failure(error: 'Queue full');

      when(mockQueuedActionRepository.createQueuedAction(action)).thenAnswer((_) async => result);

      final response = await usecase.call(action);

      expect(response.isFailure, true);
      verify(mockQueuedActionRepository.createQueuedAction(action));
    });
  });

  group('GetAllQueuedActionsUsecase', () {
    late GetAllQueuedActionsUsecase usecase;

    setUp(() {
      usecase = GetAllQueuedActionsUsecase(mockQueuedActionRepository);
    });

    test('should return list of queued actions from repository', () async {
      final queuedActions = [
        QueuedActionEntity(
          id: 1,
          repository: 'product',
          method: 'createProduct',
          param: '{}',
          isCritical: true,
        ),
      ];
      final result = Result<List<QueuedActionEntity>>.success(data: queuedActions);

      when(mockQueuedActionRepository.getAllQueuedActions()).thenAnswer((_) async => result);

      final response = await usecase.call(NoParam());

      expect(response, result);
      verify(mockQueuedActionRepository.getAllQueuedActions());
      verifyNoMoreInteractions(mockQueuedActionRepository);
    });

    test('should return failure from repository', () async {
      final result = Result<List<QueuedActionEntity>>.failure(error: 'Error');

      when(mockQueuedActionRepository.getAllQueuedActions()).thenAnswer((_) async => result);

      final response = await usecase.call(NoParam());

      expect(response, result);
      verify(mockQueuedActionRepository.getAllQueuedActions());
      verifyNoMoreInteractions(mockQueuedActionRepository);
    });
  });

  group('DeleteQueuedActionUsecase', () {
    late DeleteQueuedActionUsecase usecase;

    setUp(() {
      usecase = DeleteQueuedActionUsecase(mockQueuedActionRepository);
    });

    test('should delete queued action successfully', () async {
      const actionId = 1;
      final result = Result<void>.success(data: null);

      when(mockQueuedActionRepository.deleteQueuedAction(actionId)).thenAnswer((_) async => result);

      final response = await usecase.call(actionId);

      expect(response.isSuccess, true);
      verify(mockQueuedActionRepository.deleteQueuedAction(actionId));
      verifyNoMoreInteractions(mockQueuedActionRepository);
    });

    test('should return failure when deletion fails', () async {
      const actionId = 1;
      final result = Result<void>.failure(error: 'Delete failed');

      when(mockQueuedActionRepository.deleteQueuedAction(actionId)).thenAnswer((_) async => result);

      final response = await usecase.call(actionId);

      expect(response.isFailure, true);
      verify(mockQueuedActionRepository.deleteQueuedAction(actionId));
    });
  });
}
