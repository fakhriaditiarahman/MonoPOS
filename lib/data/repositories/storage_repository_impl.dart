import 'package:path/path.dart' as p;

import '../../core/common/result.dart';
import '../../core/services/connectivity/ping_service.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/interfaces/storage_datasource.dart';

class StorageRepositoryImpl extends StorageRepository {
  StorageRepositoryImpl({
    required PingService pingService,
    required StorageDatasource storageRemoteDataSource,
  }) : _pingService = pingService,
       _storageRemoteDataSource = storageRemoteDataSource;

  final PingService _pingService;
  final StorageDatasource _storageRemoteDataSource;

  @override
  Future<Result<String>> uploadUserPhoto(String filePath) async {
    try {
      if (!_pingService.isConnected) {
        return Result.failure(error: 'Tidak ada koneksi internet');
      }

      // Extract userId from path or generate a folder name
      final userId = _extractIdFromPath(filePath);

      return await _storageRemoteDataSource.uploadUserPhoto(
        userId: userId,
        filePath: filePath,
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> uploadProductImage(String filePath) async {
    try {
      if (!_pingService.isConnected) {
        return Result.failure(error: 'Tidak ada koneksi internet');
      }

      // Extract productId from path or generate a folder name
      final productId = _extractIdFromPath(filePath);

      return await _storageRemoteDataSource.uploadProductImage(
        productId: productId,
        filePath: filePath,
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  String _extractIdFromPath(String filePath) {
    final dirName = p.basename(p.dirname(filePath));
    if (dirName.isNotEmpty && dirName != '.') return dirName;

    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
