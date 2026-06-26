import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/product_entity.dart';
import '../entities/product_tier_entity.dart';
import '../repositories/product_repository.dart';
import 'params/base_params.dart';

class GetUserProductsUsecase extends Usecase<Result, BaseParams> {
  GetUserProductsUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<List<ProductEntity>>> call(BaseParams params) async => _productRepository.getUserProducts(
    params.param,
    orderBy: params.orderBy,
    sortBy: params.sortBy,
    limit: params.limit,
    offset: params.offset,
    contains: params.contains,
  );
}

class GetProductUsecase extends Usecase<Result, int> {
  GetProductUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<ProductEntity?>> call(int params) async => _productRepository.getProduct(params);
}

class CreateProductUsecase extends Usecase<Result, ProductEntity> {
  CreateProductUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<int>> call(ProductEntity params) async => _productRepository.createProduct(params);
}

class UpdateProductUsecase extends Usecase<Result<void>, ProductEntity> {
  UpdateProductUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<void>> call(ProductEntity params) async => _productRepository.updateProduct(params);
}

class DeleteProductUsecase extends Usecase<Result<void>, int> {
  DeleteProductUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<void>> call(int params) async => _productRepository.deleteProduct(params);
}

class GetProductByBarcodeUsecase extends Usecase<Result, String> {
  GetProductByBarcodeUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<ProductEntity?>> call(String params) async => _productRepository.getProductByBarcode(params);
}

class GetLowStockProductsUsecase extends Usecase<Result, ({String userId, int threshold})> {
  GetLowStockProductsUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<List<ProductEntity>>> call(({String userId, int threshold}) params) async =>
      _productRepository.getLowStockProducts(params.userId, params.threshold);
}

class GetProductTiersUsecase extends Usecase<Result, int> {
  GetProductTiersUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<List<ProductTierEntity>>> call(int params) async => _productRepository.getProductTiers(params);
}

class SaveProductTiersUsecase extends Usecase<Result, ({int productUnitId, List<ProductTierEntity> tiers})> {
  SaveProductTiersUsecase(this._productRepository);

  final ProductRepository _productRepository;

  @override
  Future<Result<void>> call(({int productUnitId, List<ProductTierEntity> tiers}) params) async =>
      _productRepository.saveProductTiers(params.productUnitId, params.tiers);
}
