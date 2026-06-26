import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/core/services/sync/sync_service.dart';
import 'package:mono_pos/data/datasources/interfaces/transaction_datasource.dart';
import 'package:mono_pos/data/datasources/local/transaction_local_datasource_impl.dart';
import 'package:mono_pos/data/models/transaction_model.dart';
import 'package:mono_pos/data/repositories/transaction_repository_impl.dart';
import 'package:mono_pos/domain/entities/transaction_entity.dart';
import 'package:mono_pos/domain/repositories/queued_action_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'transaction_repository_impl_test.mocks.dart';

@GenerateMocks([
  SyncService,
  TransactionLocalDatasourceImpl,
  TransactionDatasource,
  QueuedActionRepository,
])
void main() {
  late TransactionRepositoryImpl repository;
  late MockSyncService mockSyncService;
  late MockTransactionLocalDatasourceImpl mockLocalDatasource;
  late MockTransactionDatasource mockRemoteDatasource;
  late MockQueuedActionRepository mockQueuedActionRepository;

  setUp(() {
    mockSyncService = MockSyncService();
    mockLocalDatasource = MockTransactionLocalDatasourceImpl();
    mockRemoteDatasource = MockTransactionDatasource();
    mockQueuedActionRepository = MockQueuedActionRepository();

    provideDummy<Result<List<TransactionModel>>>(
      Result.success(data: <TransactionModel>[]),
    );
    provideDummy<Result<TransactionModel?>>(
      Result.success(
        data: TransactionModel(
          id: 0,
          paymentMethod: '',
          createdById: '',
          receivedAmount: 0,
          returnAmount: 0,
          totalAmount: 0,
          totalOrderedProduct: 0,
        ),
      ),
    );
    provideDummy<Result<int>>(
      Result.success(data: 0),
    );
    provideDummy<Result<void>>(
      Result.success(data: null),
    );

    repository = TransactionRepositoryImpl(
      transactionLocalDatasource: mockLocalDatasource,
      transactionRemoteDatasource: mockRemoteDatasource,
      syncService: mockSyncService,
      queuedActionRepository: mockQueuedActionRepository,
    );
  });

  group('getUserTransactions', () {
    const userId = 'user123';
    final localTransactions = [
      TransactionModel(
        id: 1,
        paymentMethod: 'cash',
        createdById: userId,
        customerName: 'Local Customer',
        receivedAmount: 50000,
        returnAmount: 0,
        totalAmount: 50000,
        totalOrderedProduct: 1,
        createdAt: '2025-01-01T10:00:00Z',
        updatedAt: '2025-01-01T10:00:00Z',
      ),
    ];

    test('returns local transactions on success', () async {
      when(
        mockLocalDatasource.getUserTransactions(
          userId,
          orderBy: anyNamed('orderBy'),
          sortBy: anyNamed('sortBy'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          contains: anyNamed('contains'),
        ),
      ).thenAnswer((_) async => Result.success(data: localTransactions));

      final result = await repository.getUserTransactions(userId);

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
      expect(result.data!.first.customerName, 'Local Customer');
    });

    test('passes query parameters correctly', () async {
      when(
        mockLocalDatasource.getUserTransactions(
          userId,
          orderBy: 'totalAmount',
          sortBy: 'ASC',
          limit: 20,
          offset: 10,
          contains: 'test',
        ),
      ).thenAnswer((_) async => Result.success(data: []));

      await repository.getUserTransactions(
        userId,
        orderBy: 'totalAmount',
        sortBy: 'ASC',
        limit: 20,
        offset: 10,
        contains: 'test',
      );

      verify(
        mockLocalDatasource.getUserTransactions(
          userId,
          orderBy: 'totalAmount',
          sortBy: 'ASC',
          limit: 20,
          offset: 10,
          contains: 'test',
        ),
      ).called(1);
    });

    test('returns failure when local datasource fails', () async {
      when(
        mockLocalDatasource.getUserTransactions(
          userId,
          orderBy: anyNamed('orderBy'),
          sortBy: anyNamed('sortBy'),
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
          contains: anyNamed('contains'),
        ),
      ).thenAnswer((_) async => Result.failure(error: 'Database error'));

      final result = await repository.getUserTransactions(userId);

      expect(result.isFailure, true);
      expect(result.error, 'Database error');
    });
  });

  group('getTransaction', () {
    const transactionId = 1;
    final localTransaction = TransactionModel(
      id: transactionId,
      paymentMethod: 'cash',
      createdById: 'user123',
      customerName: 'Local Customer',
      receivedAmount: 100000,
      returnAmount: 0,
      totalAmount: 100000,
      totalOrderedProduct: 2,
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('returns local transaction on success', () async {
      when(mockLocalDatasource.getTransaction(transactionId)).thenAnswer(
        (_) async => Result.success(data: localTransaction),
      );

      final result = await repository.getTransaction(transactionId);

      expect(result.isSuccess, true);
      expect(result.data!.customerName, 'Local Customer');
    });

    test('returns failure when local datasource fails', () async {
      when(mockLocalDatasource.getTransaction(transactionId)).thenAnswer(
        (_) async => Result.failure(error: 'Not found'),
      );

      final result = await repository.getTransaction(transactionId);

      expect(result.isFailure, true);
      expect(result.error, 'Not found');
    });
  });

  group('getTransactionsByDateRange', () {
    const userId = 'user123';
    final transactions = [
      TransactionModel(
        id: 1,
        paymentMethod: 'cash',
        createdById: userId,
        customerName: 'Customer',
        receivedAmount: 100000,
        returnAmount: 0,
        totalAmount: 100000,
        totalOrderedProduct: 2,
        createdAt: '2025-01-01T10:00:00Z',
        updatedAt: '2025-01-01T10:00:00Z',
      ),
    ];

    test('returns transactions in date range on success', () async {
      when(
        mockLocalDatasource.getTransactionsByDateRange(
          userId,
          startDate: '2025-01-01',
          endDate: '2025-01-31',
        ),
      ).thenAnswer((_) async => Result.success(data: transactions));

      final result = await repository.getTransactionsByDateRange(
        userId,
        startDate: '2025-01-01',
        endDate: '2025-01-31',
      );

      expect(result.isSuccess, true);
      expect(result.data!.length, 1);
    });

    test('returns failure when local datasource fails', () async {
      when(
        mockLocalDatasource.getTransactionsByDateRange(
          userId,
          startDate: '2025-01-01',
          endDate: '2025-01-31',
        ),
      ).thenAnswer((_) async => Result.failure(error: 'DB error'));

      final result = await repository.getTransactionsByDateRange(
        userId,
        startDate: '2025-01-01',
        endDate: '2025-01-31',
      );

      expect(result.isFailure, true);
      expect(result.error, 'DB error');
    });
  });

  group('createTransaction', () {
    final transaction = TransactionEntity(
      id: null,
      paymentMethod: 'cash',
      createdById: 'user123',
      customerName: 'New Customer',
      receivedAmount: 75000,
      returnAmount: 0,
      totalAmount: 75000,
      totalOrderedProduct: 2,
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T10:00:00Z',
    );

    test('creates locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createTransaction(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockRemoteDatasource.createTransaction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createTransaction(transaction);

      expect(result.isSuccess, true);
      expect(result.data, 1);
      verify(mockLocalDatasource.createTransaction(any)).called(1);
      verify(mockRemoteDatasource.createTransaction(any)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('creates locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.createTransaction(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createTransaction(transaction);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.createTransaction(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.createTransaction(any));
    });

    test('queues action when remote call fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createTransaction(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockRemoteDatasource.createTransaction(any)).thenAnswer((_) async => Result.failure(error: 'Server error'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createTransaction(transaction);

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.createTransaction(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
    });

    test('returns failure when local creation fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createTransaction(any)).thenAnswer((_) async => Result.failure(error: 'Database full'));

      final result = await repository.createTransaction(transaction);

      expect(result.isFailure, true);
      expect(result.error, 'Database full');
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('sets correct queued action structure', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.createTransaction(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      await repository.createTransaction(transaction);

      final captured = verify(mockQueuedActionRepository.createQueuedAction(captureAny)).captured.single;
      expect((captured as dynamic).repository, 'transaction');
      expect((captured as dynamic).method, 'createTransaction');
      expect((captured as dynamic).isCritical, false);
    });
  });

  group('updateTransaction', () {
    final transaction = TransactionEntity(
      id: 1,
      paymentMethod: 'credit_card',
      createdById: 'user123',
      customerName: 'Updated Customer',
      receivedAmount: 150000,
      returnAmount: 5000,
      totalAmount: 145000,
      totalOrderedProduct: 4,
      createdAt: '2025-01-01T10:00:00Z',
      updatedAt: '2025-01-01T12:00:00Z',
    );

    test('updates locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateTransaction(any)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.updateTransaction(any)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.updateTransaction(transaction);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updateTransaction(any)).called(1);
      verify(mockRemoteDatasource.updateTransaction(any)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('updates locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.updateTransaction(any)).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.updateTransaction(transaction);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updateTransaction(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.updateTransaction(any));
    });

    test('returns failure when local update fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.updateTransaction(any)).thenAnswer((_) async => Result.failure(error: 'Update failed'));

      final result = await repository.updateTransaction(transaction);

      expect(result.isFailure, true);
      expect(result.error, 'Update failed');
    });
  });

  group('updatePaymentStatus', () {
    const transactionId = 1;
    const status = 'paid';

    test('updates locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(
        mockLocalDatasource.updatePaymentStatus(
          transactionId,
          status,
          paymentQR: anyNamed('paymentQR'),
          paymentExternalId: anyNamed('paymentExternalId'),
        ),
      ).thenAnswer((_) async => Result.success(data: null));
      when(
        mockRemoteDatasource.updatePaymentStatus(
          transactionId,
          status,
          paymentQR: anyNamed('paymentQR'),
          paymentExternalId: anyNamed('paymentExternalId'),
        ),
      ).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.updatePaymentStatus(transactionId, status);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updatePaymentStatus(transactionId, status)).called(1);
      verify(mockRemoteDatasource.updatePaymentStatus(transactionId, status)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('updates locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(
        mockLocalDatasource.updatePaymentStatus(
          transactionId,
          status,
          paymentQR: anyNamed('paymentQR'),
          paymentExternalId: anyNamed('paymentExternalId'),
        ),
      ).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.updatePaymentStatus(transactionId, status);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.updatePaymentStatus(transactionId, status)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.updatePaymentStatus(any, any));
    });

    test('returns failure when local update fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(
        mockLocalDatasource.updatePaymentStatus(
          transactionId,
          status,
          paymentQR: anyNamed('paymentQR'),
          paymentExternalId: anyNamed('paymentExternalId'),
        ),
      ).thenAnswer((_) async => Result.failure(error: 'Update failed'));

      final result = await repository.updatePaymentStatus(transactionId, status);

      expect(result.isFailure, true);
      expect(result.error, 'Update failed');
    });
  });

  group('deleteTransaction', () {
    const transactionId = 1;

    test('deletes locally and syncs remote when online', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.deleteTransaction(transactionId)).thenAnswer((_) async => Result.success(data: null));
      when(mockRemoteDatasource.deleteTransaction(transactionId)).thenAnswer((_) async => Result.success(data: null));

      final result = await repository.deleteTransaction(transactionId);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.deleteTransaction(transactionId)).called(1);
      verify(mockRemoteDatasource.deleteTransaction(transactionId)).called(1);
      verifyNever(mockQueuedActionRepository.createQueuedAction(any));
    });

    test('deletes locally and queues action when offline', () async {
      when(mockSyncService.isOnline).thenReturn(false);
      when(mockLocalDatasource.deleteTransaction(transactionId)).thenAnswer((_) async => Result.success(data: null));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.deleteTransaction(transactionId);

      expect(result.isSuccess, true);
      verify(mockLocalDatasource.deleteTransaction(transactionId)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
      verifyNever(mockRemoteDatasource.deleteTransaction(transactionId));
    });

    test('returns failure when local deletion fails', () async {
      when(mockSyncService.isOnline).thenReturn(true);
      when(
        mockLocalDatasource.deleteTransaction(transactionId),
      ).thenAnswer((_) async => Result.failure(error: 'Not found'));

      final result = await repository.deleteTransaction(transactionId);

      expect(result.isFailure, true);
      expect(result.error, 'Not found');
    });
  });

  group('_syncRemote edge cases', () {
    test('queues action when remote call throws exception', () async {
      final transaction = TransactionEntity(
        id: null,
        paymentMethod: 'cash',
        createdById: 'user123',
        customerName: 'Test',
        receivedAmount: 50000,
        returnAmount: 0,
        totalAmount: 50000,
        totalOrderedProduct: 1,
      );

      when(mockSyncService.isOnline).thenReturn(true);
      when(mockLocalDatasource.createTransaction(any)).thenAnswer((_) async => Result.success(data: 1));
      when(mockRemoteDatasource.createTransaction(any)).thenThrow(Exception('Network error'));
      when(mockQueuedActionRepository.createQueuedAction(any)).thenAnswer((_) async => Result.success(data: 1));

      final result = await repository.createTransaction(transaction);

      expect(result.isSuccess, true);
      verify(mockRemoteDatasource.createTransaction(any)).called(1);
      verify(mockQueuedActionRepository.createQueuedAction(any)).called(1);
    });
  });
}
