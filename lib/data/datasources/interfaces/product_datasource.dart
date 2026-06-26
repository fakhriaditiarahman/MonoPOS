import '../../../core/common/result.dart';
import '../../models/product_model.dart';
import '../../models/product_tier_model.dart';
import '../../models/product_unit_model.dart';

abstract class ProductDatasource {
  Future<Result<int>> createProduct(ProductModel product);

  Future<Result<void>> updateProduct(ProductModel product);

  Future<Result<void>> deleteProduct(int id);

  Future<Result<ProductModel?>> getProduct(int id);

  Future<Result<List<ProductModel>>> getAllUserProducts(String userId);

  Future<Result<ProductModel?>> getProductByBarcode(String barcode);

  Future<Result<List<ProductModel>>> getUserProducts(
    String userId, {
    String orderBy,
    String sortBy,
    int limit,
    int? offset,
    String? contains,
  });

  Future<Result<void>> saveProductUnits(int productId, List<ProductUnitModel> units);

  Future<Result<List<ProductUnitModel>>> getProductUnits(int productId);

  Future<Result<void>> deleteProductUnits(int productId);

  Future<Result<List<ProductModel>>> getLowStockProducts(String userId, int threshold);

  Future<Result<List<ProductTierModel>>> getProductTiers(int productUnitId);

  Future<Result<void>> saveProductTiers(int productUnitId, List<ProductTierModel> tiers);

  Future<Result<void>> deleteProductTiers(int productUnitId);
}
