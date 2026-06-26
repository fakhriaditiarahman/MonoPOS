import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/common/result.dart';
import '../../domain/repositories/storage_repository.dart';

class StorageRepositoryImpl extends StorageRepository {
  @override
  Future<Result<String>> saveImageLocal({
    required String sourcePath,
    required String subDir,
    required String fileName,
  }) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return Result.failure(error: 'File not found: $sourcePath');
      }

      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/$subDir');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final targetPath = '${targetDir.path}/$fileName';
      await source.copy(targetPath);

      return Result.success(data: targetPath);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
