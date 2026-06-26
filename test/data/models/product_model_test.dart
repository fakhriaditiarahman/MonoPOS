import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/data/models/product_model.dart';
import 'package:mono_pos/data/models/product_unit_model.dart';

void main() {
  group('ProductModel', () {
    const userId = '7778024b-98a5-4df2-b912-a6e541a2ff1b';

    final baseJson = {
      'id': 1,
      'createdById': userId,
      'name': 'Teh Botol Sosro',
      'imageUrl': '',
      'stock': 100,
      'sold': 55,
      'price': 5000,
      'wholesalePrice': 4500,
      'unit': 'pcs',
      'barcode': '8991002100220',
      'description': 'Teh botol sosro 250ml',
      'units': [
        {
          'id': 1,
          'productId': 1,
          'unitName': 'pcs',
          'conversionValue': 1,
          'price': 5000,
          'wholesalePrice': 4500,
          'isBase': 1,
        },
        {
          'id': 2,
          'productId': 1,
          'unitName': 'dus',
          'conversionValue': 12,
          'price': 55000,
          'wholesalePrice': 50000,
          'isBase': 0,
        },
      ],
      'createdAt': '2025-01-01T10:00:00Z',
      'updatedAt': '2025-01-01T10:00:00Z',
    };

    group('fromJson', () {
      test('should parse JSON with all fields', () {
        final product = ProductModel.fromJson(baseJson);

        expect(product.id, 1);
        expect(product.name, 'Teh Botol Sosro');
        expect(product.price, 5000);
        expect(product.wholesalePrice, 4500);
        expect(product.stock, 100);
        expect(product.sold, 55);
        expect(product.barcode, '8991002100220');
        expect(product.unit, 'pcs');
        expect(product.units.length, 2);
      });

      test('should parse units from JSON', () {
        final product = ProductModel.fromJson(baseJson);

        expect(product.units[0].unitName, 'pcs');
        expect(product.units[0].conversionValue, 1);
        expect(product.units[0].price, 5000);
        expect(product.units[0].isBase, true);

        expect(product.units[1].unitName, 'dus');
        expect(product.units[1].conversionValue, 12);
        expect(product.units[1].price, 55000);
      });

      test('should handle missing optional fields', () {
        final minimalJson = {
          'id': 1,
          'createdById': userId,
          'name': 'Test',
          'stock': 0,
          'sold': 0,
          'price': 0,
        };

        final product = ProductModel.fromJson(minimalJson);

        expect(product.imageUrl, '');
        expect(product.unit, 'pcs');
        expect(product.wholesalePrice, isNull);
        expect(product.barcode, isNull);
        expect(product.description, isNull);
        expect(product.units, isEmpty);
      });
    });

    group('toJson', () {
      test('should serialize to JSON with all fields', () {
        final product = ProductModel.fromJson(baseJson);
        final json = product.toJson();

        expect(json['id'], 1);
        expect(json['name'], 'Teh Botol Sosro');
        expect(json['price'], 5000);
        expect(json['barcode'], '8991002100220');
        expect(json['units'], isA<List>());
        expect((json['units'] as List).length, 2);
      });

      test('should not include units in Supabase product insert', () {
        final product = ProductModel.fromJson(baseJson);
        final json = product.toJson();
        final jsonWithoutUnits = Map<String, dynamic>.from(json);
        jsonWithoutUnits.remove('units');

        expect(jsonWithoutUnits, isNot(contains('units')));
        expect(jsonWithoutUnits['name'], 'Teh Botol Sosro');
        expect(jsonWithoutUnits['price'], 5000);
      });
    });

    group('fromEntity / toEntity', () {
      test('should convert to entity and back', () {
        final product = ProductModel.fromJson(baseJson);
        final entity = product.toEntity();

        expect(entity.id, product.id);
        expect(entity.name, product.name);
        expect(entity.price, product.price);
        expect(entity.units.length, product.units.length);
      });

      test('should create model from entity', () {
        final product = ProductModel.fromJson(baseJson);
        final entity = product.toEntity();
        final model = ProductModel.fromEntity(entity);

        expect(model.name, product.name);
        expect(model.price, product.price);
        expect(model.units.length, product.units.length);
      });
    });

    group('seed data integrity', () {
      test('should match seed product format for Supabase', () {
        final product = ProductModel.fromJson(baseJson);
        final json = product.toJson();

        json.remove('units');
        json.remove('createdAt');
        json.remove('updatedAt');

        expect(json['name'], isA<String>());
        expect(json['price'], isA<int>());
        expect(json['stock'], isA<int>());
        expect(json['barcode'], isA<String>());
        expect(json['createdById'], isA<String>());
        expect(json['unit'], 'pcs');
      });

      test('seed product JSON should match Supabase products table schema', () {
        final product = ProductModel.fromJson(baseJson);
        final json = product.toJson();

        final tableColumns = [
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

        for (final col in tableColumns) {
          expect(json, contains(col), reason: 'Column $col missing from product JSON');
        }
      });

      test('seed unit JSON should match Supabase product_units table schema', () {
        final product = ProductModel.fromJson(baseJson);
        final json = product.toJson();
        final units = json['units'] as List;

        final unitColumns = [
          'productId',
          'unitName',
          'conversionValue',
          'price',
          'wholesalePrice',
          'isBase',
        ];

        for (final unit in units) {
          for (final col in unitColumns) {
            expect(unit, contains(col), reason: 'Column $col missing from unit JSON');
          }
        }
      });
    });
  });
}
