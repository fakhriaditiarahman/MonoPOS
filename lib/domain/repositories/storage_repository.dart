import '../../core/common/result.dart';

abstract class StorageRepository {
  Future<Result<String>> saveImageLocal({
    required String sourcePath,
    required String subDir,
    required String fileName,
  });
}
