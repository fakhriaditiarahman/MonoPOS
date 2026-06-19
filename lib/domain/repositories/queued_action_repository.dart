import '../../core/common/result.dart';
import '../entities/queued_action_entity.dart';

abstract class QueuedActionRepository {
  Future<Result<int>> createQueuedAction(QueuedActionEntity action);

  Future<Result<List<QueuedActionEntity>>> getAllQueuedActions();

  Future<Result<void>> deleteQueuedAction(int id);
}
