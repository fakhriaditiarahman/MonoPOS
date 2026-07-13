import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/constants/constants.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import '../../widgets/app_snack_bar.dart';
import 'payment_state.dart';

final dokuPaymentNotifierProvider = NotifierProvider.autoDispose<DokuPaymentNotifier, DokuPaymentState>(
  DokuPaymentNotifier.new,
);

class DokuPaymentNotifier extends AutoDisposeNotifier<DokuPaymentState> {
  Timer? _pollTimer;
  Timer? _elapsedTimer;

  @override
  DokuPaymentState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
    });
    return const DokuPaymentState();
  }

  Future<Result<int>> startDokuPayment({
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

      final dokuService = ref.read(dokuPaymentServiceProvider);
      final qrisResult = await dokuService.generateQris(
        orderId: orderId,
        grossAmount: totalAmount,
      );

      if (qrisResult.isFailure) {
        await DeleteTransactionUsecase(transactionRepo).call(transactionId);
        return Result.failure(error: qrisResult.error ?? 'Failed to create Doku QRIS invoice');
      }

      final qrisData = qrisResult.data!;

      await UpdatePaymentStatusUsecase(transactionRepo).call(
        transactionId,
        'pending',
        paymentQR: qrisData.qrContent,
        paymentExternalId: qrisData.partnerReferenceNo,
      );

      // Print QR slip
      final printer = ref.read(printerServiceProvider);
      final storeName = ref.read(sharedPreferencesProvider).getString(Constants.storeNameKey) ?? '';
      await printer.printQrCode(
        qrData: qrisData.qrContent,
        totalAmount: totalAmount,
        storeName: storeName,
        merchantName: 'Doku QRIS',
      );

      state = state.copyWith(
        transaction: transaction.copyWith(
          id: transactionId,
          paymentStatus: 'pending',
          paymentQR: qrisData.qrContent,
          paymentExternalId: qrisData.partnerReferenceNo,
        ),
        qrCode: qrisData.qrContent,
        paymentStatus: 'pending',
        isPolling: false,
        elapsedSeconds: 0,
        partnerReferenceNo: qrisData.partnerReferenceNo,
        referenceNo: qrisData.referenceNo,
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
    final dokuService = ref.read(dokuPaymentServiceProvider);
    int attempts = 0;

    while (state.paymentStatus == 'pending' && attempts < 3) {
      await Future.delayed(const Duration(seconds: 15));
      attempts++;

      final result = await dokuService.queryQrisStatus(
        partnerReferenceNo: state.partnerReferenceNo,
        referenceNo: state.referenceNo,
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

    final dokuService = ref.read(dokuPaymentServiceProvider);
    final result = await dokuService.queryQrisStatus(
      partnerReferenceNo: state.partnerReferenceNo,
      referenceNo: state.referenceNo,
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
    state = const DokuPaymentState();
  }
}
