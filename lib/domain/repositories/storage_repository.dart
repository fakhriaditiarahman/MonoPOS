import '../../core/common/result.dart';

abstract class StorageRepository {
  Future<Result<String>> uploadUserPhoto(String filePath);

  Future<Result<String>> uploadProductImage(String filePath);
}
