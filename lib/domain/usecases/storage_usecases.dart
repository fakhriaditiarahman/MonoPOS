import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/storage_repository.dart';

class SaveImageLocalUsecase extends Usecase<Result<String>, ({String sourcePath, String subDir, String fileName})> {
  SaveImageLocalUsecase(this._storageRepository);

  final StorageRepository _storageRepository;

  @override
  Future<Result<String>> call(({String sourcePath, String subDir, String fileName}) params) async =>
      _storageRepository.saveImageLocal(
        sourcePath: params.sourcePath,
        subDir: params.subDir,
        fileName: params.fileName,
      );
}
