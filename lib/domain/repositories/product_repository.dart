import '../../core/common/result.dart';
import '../entities/product_entity.dart';
import '../entities/product_tier_entity.dart';
import '../entities/product_unit_entity.dart';

abstract class ProductRepository {
  Future<Result<ProductEntity?>> getProduct(int productId);

  Future<Result<ProductEntity?>> getProductByBarcode(String barcode);

  Future<Result<int>> createProduct(ProductEntity product);

  Future<Result<void>> updateProduct(ProductEntity product);

  Future<Result<void>> deleteProduct(int productId);

  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy,
    String sortBy,
    int limit,
    int? offset,
    String? contains,
  });

  Future<Result<List<ProductUnitEntity>>> getProductUnits(int productId);

  Future<Result<void>> saveProductUnits(int productId, List<ProductUnitEntity> units);

  Future<Result<List<ProductEntity>>> getLowStockProducts(String userId, int threshold);

  Future<Result<List<ProductTierEntity>>> getProductTiers(int productUnitId);

  Future<Result<void>> saveProductTiers(int productUnitId, List<ProductTierEntity> tiers);
}
