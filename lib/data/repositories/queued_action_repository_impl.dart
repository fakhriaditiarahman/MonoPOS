import '../../../core/common/result.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../datasources/local/queued_action_local_datasource_impl.dart';
import '../models/queued_action_model.dart';

class QueuedActionRepositoryImpl extends QueuedActionRepository {
  final QueuedActionLocalDatasourceImpl _localDatasource;

  QueuedActionRepositoryImpl({required QueuedActionLocalDatasourceImpl localDatasource})
    : _localDatasource = localDatasource;

  @override
  Future<Result<int>> createQueuedAction(QueuedActionEntity action) async {
    try {
      final model = QueuedActionModel.fromEntity(action);
      final res = await _localDatasource.createQueuedAction(model);
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: res.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<QueuedActionEntity>>> getAllQueuedActions() async {
    try {
      final res = await _localDatasource.getAllUserQueuedAction();
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(
        data: res.data!.map((e) => e.toEntity()).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteQueuedAction(int id) async {
    try {
      final res = await _localDatasource.deleteQueuedAction(id);
      if (res.isFailure) return Result.failure(error: res.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
