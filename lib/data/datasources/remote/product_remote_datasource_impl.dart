import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/product_model.dart';
import '../../models/product_unit_model.dart';
import '../interfaces/product_datasource.dart';

class ProductRemoteDatasourceImpl extends ProductDatasource {
  ProductRemoteDatasourceImpl();

  SupabaseClient? get _client => SupabaseService.client;

  @override
  Future<Result<int>> createProduct(ProductModel product) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = product.toJson();
      final units = json.remove('units') as List<dynamic>?;

      await client.from(SupabaseConfig.productsTable).insert(json);

      if (units != null && units.isNotEmpty) {
        for (final unit in units) {
          (unit as Map<String, dynamic>)['productId'] = product.id;
        }
        await client.from(SupabaseConfig.productUnitsTable).insert(units);
      }

      return Result.success(data: product.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductModel product) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = product.toJson();
      final units = json.remove('units') as List<dynamic>?;

      await client.from(SupabaseConfig.productsTable).update(json).eq('id', product.id);

      if (units != null) {
        await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', product.id);

        for (final unit in units) {
          (unit as Map<String, dynamic>)['productId'] = product.id;
        }
        await client.from(SupabaseConfig.productUnitsTable).insert(units);
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int id) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', id);

      await client.from(SupabaseConfig.productsTable).delete().eq('id', id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProduct(int id) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.productsTable).select().eq('id', id).maybeSingle();

      if (res == null) return Result.success(data: null);

      final product = ProductModel.fromJson(Map<String, dynamic>.from(res));
      await _loadUnits(client, product);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getAllUserProducts(String userId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client.from(SupabaseConfig.productsTable).select().eq('createdById', userId);

      final products = <ProductModel>[];
      for (final row in res) {
        final product = ProductModel.fromJson(Map<String, dynamic>.from(row));
        await _loadUnits(client, product);
        products.add(product);
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProductByBarcode(String barcode) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.productsTable).select().eq('barcode', barcode).maybeSingle();

      if (res == null) return Result.success(data: null);

      final product = ProductModel.fromJson(Map<String, dynamic>.from(res));
      await _loadUnits(client, product);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      dynamic query = client.from(SupabaseConfig.productsTable).select().eq('createdById', userId);

      if (contains != null && contains.isNotEmpty) {
        query = query.ilike('name', '%$contains%');
      }

      query = query.order(orderBy, ascending: sortBy == 'ASC').limit(limit);

      if (offset != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final res = await query as List<dynamic>;

      final products = <ProductModel>[];
      for (final row in res) {
        final product = ProductModel.fromJson(Map<String, dynamic>.from(row));
        await _loadUnits(client, product);
        products.add(product);
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductUnits(int productId, List<ProductUnitModel> units) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', productId);

      for (final unit in units) {
        unit.productId = productId;
      }
      await client.from(SupabaseConfig.productUnitsTable).insert(units.map((e) => e.toJson()).toList());

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductUnitModel>>> getProductUnits(int productId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client.from(SupabaseConfig.productUnitsTable).select().eq('productId', productId);

      return Result.success(
        data: res.map((e) => ProductUnitModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProductUnits(int productId) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', productId);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _loadUnits(SupabaseClient client, ProductModel product) async {
    final unitRes = await client.from(SupabaseConfig.productUnitsTable).select().eq('productId', product.id);

    product.units = unitRes.map((e) => ProductUnitModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}
