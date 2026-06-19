import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/core/services/sync/sync_service.dart';
import 'package:mono_pos/data/datasources/interfaces/product_datasource.dart';
import 'package:mono_pos/data/datasources/local/product_local_datasource_impl.dart';
import 'package:mono_pos/data/models/product_model.dart';
import 'package:mono_pos/data/models/product_unit_model.dart';
import 'package:mono_pos/data/repositories/product_repository_impl.dart';
import 'package:mono_pos/domain/entities/product_entity.dart';
import 'package:mono_pos/domain/repositories/queued_action_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'product_repository_impl_test.mocks.dart';

@GenerateMocks([
  SyncService,
  ProductLocalDatasourceImpl,
  ProductDatasource,
  QueuedActionRepository,
])
void main() {
  late ProductRepositoryImpl repository;
  late MockSyncService mockSyncService;
  late MockProductLocalDatasourceImpl mockLocalDatasource;
  late MockProductDatasource mockRemoteDatasource;
  late MockQueuedActionRepository mockQueuedActionRepository;

  setUp(() {
    mockSyncService = MockSyncService();
    mockLocalDatasource = MockProductLocalDatasourceImpl();
    mockRemoteDatasource = MockProductDatasource();
    mockQueuedActionRepository = MockQueuedActionRepository();

    provideDummy<Result<List<ProductModel>>>(
      Result.success(data: <ProductModel>[]),
    );
    provideDummy<Result<ProductModel?>>(
      Result.success(
        data: ProductModel(
          id: 0,
          createdById: '',
          name: '',
          imageUrl: '',
          stock: 0,
          sold: 0,
          price: 0,
        ),
      ),
    );
    provideDummy<Result<int>>(
      Result.success(data: 0),
    );
    provideDummy<Result<List<ProductUnitModel>>>(
      Result.success(data: <ProductUnitModel>[]),
    );
    provideDummy<Result<void>>(
      Result.success(data: null),
    );

    repository = ProductRepositoryImpl(
      productLocalDatasource: mockLocalDatasource,
      productRemoteDatasource: mockRemoteDatasource,
      syncService: mockSyncService,
      queuedActionRepository: mockQueuedActionRepository,
    );
  });

  group('getUserProducts', () {
    const userId = 'user123';
    final localProducts = [
      ProductModel(
        id: 1,
        createdById: userId,
        name: 'Local Product',
        imageUrl: 'https://example.com/local.jpg',
        stock: 15,
        sold: 3,
        price: 15000,
        createdAt: '2025-01-01T10:00:00Z',
        updatedAt: '2025-01-01T10:00:00Z',
      ),
    ];

    test('returns local products on success', () async {
      when(
        mockLocalDatasource.getUserProducts(
          userId,
          orderBy: anyNamed('orderBy'),
          sortBy: anyNamed('sortBy'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          contains: anyNamed('contains'),
        ),
      ).thenAnswer((_) async => Result.success(data: localProducts));

      final result = await repository.getUserProducts(userId);

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data!.first.name, 'Local Product');
    });

    test('passes query parameters correctly', () async {
      when(
        mockLocalDatasource.getUserProducts(
          userId,
          orderBy: 'name',
          sortBy: 'ASC',
          limit: 20,
          offset: 10,
          contains: 'test',
        ),
      ).thenAnswer((_) async => Result.success(data: []));

      await repository.getUserProducts(
        userId,
        orderBy: 'name',
        sortBy: 'ASC',
        limit: 20,
        offset: 10,
        contains: 'test',
      );

      verify(
        mockLocalDatasource.getUserProducts(
          userId,
          orderBy: 'name',
          sortBy: 'ASC',
          limit: 20,
          offset: 10,
          contains: 'test',
        ),
      ).called(1);
    });

    test('returns failure when local datasource fails', () async {
      when(
        mockLocalDatasource.getUserProducts(
          userId,
          orderBy: anyNamed('orderBy'),
          sortBy: anyNamed('sortBy'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          contains: anyNamed('contains'),
        ),
      ).thenAnswer((_) async => Result.failure(error: 'Database error'));

      final result = await repository.getUserProducts(userId);

      expect(result.isFailure, true);
      expect(result.error, 'Database error');
    });
  });

  group('getProduct', () {
    const productId = 1;
    final localProduct = ProductModel(
      id: productId,
      createdById: 'user123',
      name: 'Local Product',
      imageUrl: 'https://example.com/local.jpg',
      stock: 10,
      sold: 2,
      price: 10000,
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('returns local product on success', () async {
      when(mockLocalDatasource.getProduct(productId)).thenAnswer((_) async => Result.success(data: localProduct));

      final result = await repository.getProduct(productId);

      expect(result.isSuccess, true);
      expect(result.data!.name, 'Local Product');
    });

    test('returns failure when local datasource fails', () async {
      when(mockLocalDatasource.getProduct(productId)).thenAnswer((_) async => Result.failure(error: 'Not found'));

      final result = await repository.getProduct(productId);

      expect(result.isFailure, true);
      expect(result.error, 'Not found');
    });
  });

  group('getProductByBarcode', () {
    const barcode = '123456789';
    final localProduct = ProductModel(
      id: 1,
      createdById: 'user123',
      name: 'Barcode Product',
      imageUrl: '',
      stock: 5,
      sold: 0,
      price: 5000,
      barcode: barcode,
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('returns product by barcode on success', () async {
      when(mockLocalDatasource.getProductByBarcode(barcode)).thenAnswer((_) async => Result.success(data: localProduct));

      final result = await repository.getProductByBarcode(barcode);

      expect(result.isSuccess, true);
      expect(result.data!.barcode, barcode);
    });

    test('returns null when not found', () async {
      when(mockLocalDatasource.getProductByBarcode(barcode)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.getProductByBarcode(barcode);

      expect(result.isSuccess, true);
      expect(result.data, isNull);
    });
  });

  group('createProduct', () {
    final product = ProductEntity(
      id: null,
      createdById: 'user123',
      name: 'New Product',
      imageUrl: '',
      stock: 25,
      sold: 0,
      price: 25000,
    );

    test('creates locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createProduct(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockRemoteDatasource.createProduct(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createProduct(product);

      expect(result.isSuccess, true);
      expect(result.data, 1);
      verify(mockLocalDatasource.createProduct(any)).called(1);
      verify(mockRemoteDatasource.createProduct(any)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('creates locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.createProduct(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createProduct(product);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.createProduct(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.createProduct(any));
    });

    test('queues action when remote call fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createProduct(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockRemoteDatasource.createProduct(any)).thenAnswer((_) async => Result.failure(error: 'Server error'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createProduct(product);

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.createProduct(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
    });

    test('returns failure when local creation fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createProduct(any)).thenAnswer((_) async => Result.failure(error: 'Database error'));

      final result = await repository.createProduct(product);

      expect(result.isFailure, true);
      expect(result.error, 'Database error');
      verifyNever(mockRemoteDatasource.createProduct(any));
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });
  });

  group('updateProduct', () {
    final product = ProductEntity(
      id: 1,
      createdById: 'user123',
      name: 'Updated Product',
      imageUrl: '',
      stock: 30,
      sold: 8,
      price: 30000,
    );

    test('updates locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateProduct(any)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.updateProduct(any)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.updateProduct(product);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updateProduct(any)).called(1);
      verify(mockRemoteDatasource.updateProduct(any)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('updates locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.updateProduct(any)).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.updateProduct(product);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updateProduct(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.updateProduct(any));
    });

    test('returns failure when local update fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateProduct(any)).thenAnswer((_) async => Result.failure(error: 'Update failed'));

      final result = await repository.updateProduct(product);

      expect(result.isFailure, true);
      expect(result.error, 'Update failed');
    });
  });

  group('deleteProduct', () {
    const productId = 1;

    test('deletes locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.deleteProduct(productId)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.deleteProduct(productId)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.deleteProduct(productId);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.deleteProduct(productId)).called(1);
      verify(mockRemoteDatasource.deleteProduct(productId)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('deletes locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.deleteProduct(productId)).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.deleteProduct(productId);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.deleteProduct(productId)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.deleteProduct(productId));
    });

    test('returns failure when local deletion fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.deleteProduct(productId)).thenAnswer((_) async => Result.failure(error: 'Delete failed'));

      final result = await repository.deleteProduct(productId);

      expect(result.isFailure, true);
      expect(result.error, 'Delete failed');
    });
  });

  group('getProductUnits', () {
    const productId = 1;

    test('returns product units on success', () async {
      when(mockLocalDatasource.getProductUnits(productId)).thenAnswer((_) async => Result.success(data: []));

      final result = await repository.getProductUnits(productId);

      expect(result.isSuccess, true);
    });
  });

  group('saveProductUnits', () {
    const productId = 1;

    test('saves units locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.saveProductUnits(any, any)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.saveProductUnits(any, any)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.saveProductUnits(productId, []);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.saveProductUnits(any, any)).called(1);
      verify(mockRemoteDatasource.saveProductUnits(any, any)).called(1);
    });
  });

  group('_syncRemote edge cases', () {
    test('queues action when remote call throws exception', () async {
      final product = ProductEntity(
        id: null,
        createdById: 'user123',
        name: 'Test',
        imageUrl: '',
        stock: 10,
        sold: 0,
        price: 10000,
      );

      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createProduct(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockRemoteDatasource.createProduct(any)).thenThrow(Exception('Network error'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createProduct(product);

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.createProduct(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
    });
  });
}
