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

      final midtrans = ref.read(midtransPaymentServiceProvider);
      final chargeResult = await midtrans.createQrisCharge(
        orderId: orderId,
        grossAmount: totalAmount,
      );

      if (chargeResult.isFailure) {
        await DeleteTransactionUsecase(transactionRepo).call(transactionId);
        return Result.failure(error: chargeResult.error ?? 'Failed to create QRIS charge');
      }

      final qrisData = chargeResult.data!;

      await UpdatePaymentStatusUsecase(transactionRepo).call(
        transactionId,
        'pending',
        paymentQR: qrisData.qrCode,
        paymentExternalId: qrisData.transactionId,
      );

      // Print QR slip (fire-and-forget)
      final printer = ref.read(printerServiceProvider);
      final storeName = ref.read(sharedPreferencesProvider).getString(Constants.storeNameKey) ?? '';
      printer.printQrCode(
        qrData: qrisData.qrCode,
        totalAmount: totalAmount,
        storeName: storeName,
        merchantName: midtrans.merchantName,
      );

      state = state.copyWith(
        transaction: transaction.copyWith(
          id: transactionId,
          paymentStatus: 'pending',
          paymentQR: qrisData.qrCode,
          paymentExternalId: qrisData.transactionId,
        ),
        qrCode: qrisData.qrCode,
        paymentStatus: 'pending',
        isPolling: false,
        elapsedSeconds: 0,
      );

      _startPolling(orderId, transactionId);

      return Result.success(data: transactionId);
    } catch (e) {
      state = state.copyWith(isPolling: false, errorMessage: e.toString());
      return Result.failure(error: e.toString());
    }
  }

  void _startPolling(String orderId, int transactionId) {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.elapsedSeconds >= 300) {
        _onPaymentFailed('Waktu pembayaran habis');
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    _pollStatus(orderId, transactionId);
  }

  void _pollStatus(String orderId, int transactionId) async {
    final midtrans = ref.read(midtransPaymentServiceProvider);

    while (state.paymentStatus == 'pending') {
      await Future.delayed(const Duration(seconds: 5));

      final result = await midtrans.checkTransactionStatus(orderId);

      if (result.isFailure) continue;

      final status = result.data!;

      if (status == 'paid') {
        _onPaymentSuccess(transactionId, orderId);
        return;
      } else if (status == 'failed') {
        _onPaymentFailed('Pembayaran gagal');
        return;
      }
    }
  }

  Future<void> _onPaymentSuccess(int transactionId, String orderId) async {
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
