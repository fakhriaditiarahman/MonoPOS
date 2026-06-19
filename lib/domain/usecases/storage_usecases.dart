import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/storage_repository.dart';

class UploadUserPhotoUsecase extends Usecase<Result<String>, String> {
  UploadUserPhotoUsecase(this._storageRepository);

  final StorageRepository _storageRepository;

  @override
  Future<Result<String>> call(String params) async => _storageRepository.uploadUserPhoto(params);
}

class UploadProductImageUsecase extends Usecase<Result<String?>, String> {
  UploadProductImageUsecase(this._storageRepository);

  final StorageRepository _storageRepository;

  @override
  Future<Result<String?>> call(String params) async => _storageRepository.uploadProductImage(params);
}
