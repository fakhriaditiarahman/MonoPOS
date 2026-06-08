import '../../core/common/result.dart';
import '../entities/product_entity.dart';

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
}
