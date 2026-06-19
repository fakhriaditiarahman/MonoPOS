import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import 'payment_state.dart';

final qrisPaymentNotifierProvider = NotifierProvider.autoDispose<QrisPaymentNotifier, QrisPaymentState>(
  QrisPaymentNotifier.new,
);

class QrisPaymentNotifier extends AutoDisposeNotifier<QrisPaymentState> {
  Timer? _pollTimer;
  Timer? _elapsedTimer;
  int _totalAmount = 0;

  @override
  QrisPaymentState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
    });
    return const QrisPaymentState();
  }

  Future<Result<int>> startQrisPayment({
    required TransactionEntity transaction,
    required int totalAmount,
  }) async {
    state = state.copyWith(isPolling: true);
    _totalAmount = totalAmount;

    try {
      final transactionRepo = ref.read(transactionRepositoryProvider);
      final saveResult = await CreateTransactionUsecase(transactionRepo).call(
        transaction.copyWith(paymentStatus: 'pending'),
      );

      if (saveResult.isFailure) {
        return Result.failure(error: saveResult.error ?? 'Failed to save transaction');
      }

      final transactionId = saveResult.data!;
      final orderId = transactionId.toString();

      final interactiveQris = ref.read(interactiveQrisPaymentServiceProvider);
      final invoiceResult = await interactiveQris.createQrisInvoice(
        orderId: orderId,
        grossAmount: totalAmount,
      );

      if (invoiceResult.isFailure) {
        await DeleteTransactionUsecase(transactionRepo).call(transactionId);
        return Result.failure(error: invoiceResult.error ?? 'Failed to create QRIS invoice');
      }

      final qrisData = invoiceResult.data!;

      await UpdatePaymentStatusUsecase(transactionRepo).call(
        transactionId,
        'pending',
        paymentQR: qrisData.qrisContent,
        paymentExternalId: qrisData.qrisInvoiceId,
      );

      // Print QR slip (fire-and-forget)
      final printer = ref.read(printerServiceProvider);
      final storeName = ref.read(sharedPreferencesProvider).getString(Constants.storeNameKey) ?? '';
      printer.printQrCode(
        qrData: qrisData.qrisContent,
        totalAmount: totalAmount,
        storeName: storeName,
        merchantName: interactiveQris.merchantName,
      );

      state = state.copyWith(
        transaction: transaction.copyWith(
          id: transactionId,
          paymentStatus: 'pending',
          paymentQR: qrisData.qrisContent,
          paymentExternalId: qrisData.qrisInvoiceId,
        ),
        qrCode: qrisData.qrisContent,
        paymentStatus: 'pending',
        isPolling: false,
        elapsedSeconds: 0,
        qrisInvoiceId: qrisData.qrisInvoiceId,
        qrisNmid: qrisData.qrisNmid,
      );

      _startPolling(transactionId);

      return Result.success(data: transactionId);
    } catch (e) {
      state = state.copyWith(isPolling: false, errorMessage: e.toString());
      return Result.failure(error: e.toString());
    }
  }

  void _startPolling(int transactionId) {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.elapsedSeconds >= 1800) {
        _onPaymentFailed('Waktu pembayaran habis');
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    _autoPollStatus(transactionId);
  }

  Future<void> _autoPollStatus(int transactionId) async {
    final interactiveQris = ref.read(interactiveQrisPaymentServiceProvider);
    int attempts = 0;

    while (state.paymentStatus == 'pending' && attempts < 3) {
      await Future.delayed(const Duration(seconds: 15));
      attempts++;

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final result = await interactiveQris.checkInvoiceStatus(
        invoiceId: state.qrisInvoiceId,
        amount: _totalAmount,
        date: dateStr,
      );

      if (result.isFailure) continue;

      final status = result.data!;

      if (status == 'paid') {
        _onPaymentSuccess(transactionId);
        return;
      }
    }

    if (state.paymentStatus == 'pending') {
      state = state.copyWith(autoCheckDone: true);
    }
  }

  Future<void> checkPaymentManually() async {
    if (state.transaction == null) return;

    state = state.copyWith(isManualChecking: true);

    final interactiveQris = ref.read(interactiveQrisPaymentServiceProvider);
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = await interactiveQris.checkInvoiceStatus(
      invoiceId: state.qrisInvoiceId,
      amount: _totalAmount,
      date: dateStr,
    );

    if (result.isSuccess && result.data == 'paid') {
      _onPaymentSuccess(state.transaction!.id!);
    } else {
      state = state.copyWith(isManualChecking: false);
    }
  }

  Future<void> _onPaymentSuccess(int transactionId) async {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    state = state.copyWith(paymentStatus: 'paid');

    final transactionRepo = ref.read(transactionRepositoryProvider);
    await UpdatePaymentStatusUsecase(transactionRepo).call(transactionId, 'paid');

    final transactionResult = await GetTransactionUsecase(transactionRepo).call(transactionId);
    if (transactionResult.isSuccess && transactionResult.data != null) {
      final printer = ref.read(printerServiceProvider);
      printer.printTransaction(transactionResult.data!);
    }
  }

  void _onPaymentFailed(String message) {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    state = state.copyWith(paymentStatus: 'failed', errorMessage: message);
  }

  void cancelPolling() {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
  }

  void reset() {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    state = const QrisPaymentState();
  }
}
