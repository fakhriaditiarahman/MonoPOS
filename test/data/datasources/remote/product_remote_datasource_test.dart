import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/data/datasources/remote/product_remote_datasource_impl.dart';
import 'package:mono_pos/data/models/product_model.dart';
import 'package:mono_pos/data/models/product_unit_model.dart';

void main() {
  late ProductRemoteDatasourceImpl datasource;

  const userId = '7778024b-98a5-4df2-b912-a6e541a2ff1b';

  setUp(() {
    datasource = ProductRemoteDatasourceImpl(clientOverride: null);
  });

  group('ProductRemoteDatasourceImpl', () {
    group('createProduct', () {
      test('should return failure when Supabase not configured', () async {
        final product = ProductModel(
          id: 1,
          name: 'Teh Botol Sosro',
          createdById: userId,
          imageUrl: '',
          price: 5000,
          wholesalePrice: 4500,
          stock: 100,
          sold: 55,
          barcode: '8991002100220',
          unit: 'pcs',
          description: 'Teh botol sosro 250ml',
          units: [
            ProductUnitModel(
              id: 1,
              productId: 1,
              unitName: 'pcs',
              conversionValue: 1,
              price: 5000,
              wholesalePrice: 4500,
              isBase: true,
            ),
            ProductUnitModel(
              id: 2,
              productId: 1,
              unitName: 'dus',
              conversionValue: 12,
              price: 55000,
              wholesalePrice: 50000,
              isBase: false,
            ),
          ],
        );

        final result = await datasource.createProduct(product);

        expect(result.isFailure, true);
        expect(result.error, 'Supabase not configured');
      });
    });

    group('getProduct', () {
      test('should return success with null when Supabase not configured', () async {
        final result = await datasource.getProduct(1);

        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });
    });

    group('getAllUserProducts', () {
      test('should return empty list when Supabase not configured', () async {
        final result = await datasource.getAllUserProducts(userId);

        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('getProductByBarcode', () {
      test('should return success with null when Supabase not configured', () async {
        final result = await datasource.getProductByBarcode('8991002100220');

        expect(result.isSuccess, true);
        expect(result.data, isNull);
      });
    });

    group('getProductUnits', () {
      test('should return empty list when Supabase not configured', () async {
        final result = await datasource.getProductUnits(1);

        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('getLowStockProducts', () {
      test('should return empty list when Supabase not configured', () async {
        final result = await datasource.getLowStockProducts(userId, 5);

        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });
    });

    group('data format', () {
      test('product JSON should match Supabase products table schema', () {
        final product = ProductModel(
          id: 1,
          name: 'Teh Botol Sosro',
          createdById: userId,
          imageUrl: '',
          price: 5000,
          wholesalePrice: 4500,
          stock: 100,
          sold: 55,
          barcode: '8991002100220',
          unit: 'pcs',
          description: 'Teh botol sosro 250ml',
        );

        final json = product.toJson();
        json.remove('units');

        final expectedColumns = [
          'id',
          'createdById',
          'name',
          'imageUrl',
          'stock',
          'sold',
          'price',
          'wholesalePrice',
          'unit',
          'barcode',
          'description',
        ];

        for (final col in expectedColumns) {
          expect(json, contains(col), reason: 'Column $col missing from product JSON');
        }
      });

      test('unit JSON should match Supabase product_units table schema', () {
        final unit = ProductUnitModel(
          id: 1,
          productId: 1,
          unitName: 'pcs',
          conversionValue: 1,
          price: 5000,
          wholesalePrice: 4500,
          isBase: true,
        );

        final json = unit.toJson();

        final expectedColumns = [
          'id',
          'productId',
          'unitName',
          'conversionValue',
          'price',
          'wholesalePrice',
          'isBase',
        ];

        for (final col in expectedColumns) {
          expect(json, contains(col), reason: 'Column $col missing from unit JSON');
        }
      });

      test('product JSON should not include units for INSERT operation', () {
        final product = ProductModel(
          id: 1,
          name: 'Teh Botol Sosro',
          createdById: userId,
          imageUrl: '',
          price: 5000,
          stock: 100,
          sold: 55,
        );

        final json = product.toJson();
        json.remove('units');

        expect(json, isNot(contains('units')));
      });
    });
  });
}
