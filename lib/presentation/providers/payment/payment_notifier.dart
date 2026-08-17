import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import '../../widgets/app_snack_bar.dart';
import 'payment_state.dart';

final klikQrisPaymentNotifierProvider = NotifierProvider<KlikQrisPaymentNotifier, KlikQrisPaymentState>(
  KlikQrisPaymentNotifier.new,
);

class KlikQrisPaymentNotifier extends Notifier<KlikQrisPaymentState> {
  Timer? _pollTimer;
  Timer? _elapsedTimer;

  @override
  KlikQrisPaymentState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
    });
    return const KlikQrisPaymentState();
  }

  Future<Result<int>> startKlikQrisPayment({
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

      final klikQrisService = ref.read(klikQrisPaymentServiceProvider);
      final qrisResult = await klikQrisService.generateQris(
        orderId: orderId,
        grossAmount: totalAmount,
      );

      if (qrisResult.isFailure) {
        await DeleteTransactionUsecase(transactionRepo).call(transactionId);
        state = state.copyWith(isPolling: false, errorMessage: qrisResult.error?.toString());
        return Result.failure(error: qrisResult.error ?? 'Failed to create KlikQRIS invoice');
      }

      final qrisData = qrisResult.data!;
      final paymentQR = qrisData.qrImageBase64.isNotEmpty ? qrisData.qrImageBase64 : qrisData.qrUrl;
      final paymentTimeout = qrisData.expiredMinutes * 60;

      cl(
        '[KlikQRIS] paymentQR: len=${paymentQR.length} prefix=${paymentQR.length > 20 ? paymentQR.substring(0, 20) : paymentQR}',
      );

      await UpdatePaymentStatusUsecase(transactionRepo).call(
        transactionId,
        'pending',
        paymentQR: paymentQR,
        paymentExternalId: qrisData.orderId,
      );

      state = state.copyWith(
        transaction: transaction.copyWith(
          id: transactionId,
          paymentStatus: 'pending',
          paymentQR: paymentQR,
          paymentExternalId: qrisData.orderId,
        ),
        qrCode: paymentQR,
        paymentStatus: 'pending',
        isPolling: false,
        elapsedSeconds: 0,
        orderId: qrisData.orderId,
        signature: qrisData.signature,
        totalAmount: qrisData.totalAmount,
      );

      _startPolling(transactionId, paymentTimeout);

      return Result.success(data: transactionId);
    } catch (e) {
      state = state.copyWith(isPolling: false, errorMessage: e.toString());
      return Result.failure(error: e.toString());
    }
  }

  void _startPolling(int transactionId, int timeoutSeconds) {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.elapsedSeconds >= timeoutSeconds) {
        _onPaymentFailed('Waktu pembayaran habis');
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    _autoPollStatus(transactionId);
  }

  Future<void> _autoPollStatus(int transactionId) async {
    final klikQrisService = ref.read(klikQrisPaymentServiceProvider);
    int attempts = 0;

    while (state.paymentStatus == 'pending' && attempts < 3) {
      await Future.delayed(const Duration(seconds: 15));
      attempts++;

      final result = await klikQrisService.queryQrisStatus(orderId: state.orderId);

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

    final klikQrisService = ref.read(klikQrisPaymentServiceProvider);
    final result = await klikQrisService.queryQrisStatus(orderId: state.orderId);

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
      final printResult = await printer.printTransaction(transactionResult.data!);
      if (printResult.isFailure) {
        AppSnackBar.showError('Cetak struk gagal: ${printResult.error}');
      }
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
    state = const KlikQrisPaymentState();
  }
}
