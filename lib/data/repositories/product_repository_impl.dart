import '../../../core/common/result.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/product_repository.dart';
import '../datasources/local/product_local_datasource_impl.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl extends ProductRepository {
  final ProductLocalDatasourceImpl productLocalDatasource;

  ProductRepositoryImpl({
    required this.productLocalDatasource,
  });

  @override
  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      final local = await productLocalDatasource.getUserProducts(
        userId,
        orderBy: orderBy,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        contains: contains,
      );

      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductEntity?>> getProduct(int productId) async {
    try {
      final local = await productLocalDatasource.getProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductEntity?>> getProductByBarcode(String barcode) async {
    try {
      final local = await productLocalDatasource.getProductByBarcode(barcode);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<int>> createProduct(ProductEntity product) async {
    try {
      final data = ProductModel.fromEntity(product);

      final local = await productLocalDatasource.createProduct(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int productId) async {
    try {
      final local = await productLocalDatasource.deleteProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductEntity product) async {
    try {
      final local = await productLocalDatasource.updateProduct(ProductModel.fromEntity(product));
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
