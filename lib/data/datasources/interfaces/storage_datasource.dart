import '../../../core/common/result.dart';

abstract class StorageDatasource {
  Future<Result<String>> uploadUserPhoto({
    required String userId,
    required String filePath,
  });

  Future<Result<String>> uploadProductImage({
    required String productId,
    required String filePath,
  });
}
