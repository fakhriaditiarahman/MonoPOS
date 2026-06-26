import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/receivable_payment_entity.dart';
import '../../../domain/usecases/customer_usecases.dart';
import '../../../domain/usecases/receivable_payment_usecases.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import 'piutang_detail_state.dart';

final piutangDetailNotifierProvider = NotifierProvider.autoDispose<PiutangDetailNotifier, PiutangDetailState>(
  PiutangDetailNotifier.new,
);

class PiutangDetailNotifier extends AutoDisposeNotifier<PiutangDetailState> {
  @override
  PiutangDetailState build() {
    return const PiutangDetailState();
  }

  Future<void> load(int transactionId) async {
    state = state.copyWith(isLoading: true);

    try {
      final transactionRepository = ref.read(transactionRepositoryProvider);
      final txnRes = await GetTransactionUsecase(transactionRepository).call(
        transactionId,
      );

      if (txnRes.isFailure || txnRes.data == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final paymentRepo = ref.read(receivablePaymentRepositoryProvider);
      final payRes = await GetPaymentsByTransactionUsecase(paymentRepo).call(
        transactionId,
      );

      state = PiutangDetailState(
        transaction: txnRes.data,
        payments: payRes.isSuccess ? payRes.data ?? [] : [],
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Result<void>> payInstallment({
    required int transactionId,
    required int totalAmount,
    required int currentReceived,
    String? customerId,
    required int paymentAmount,
    String? notes,
  }) async {
    try {
      final transactionRepository = ref.read(transactionRepositoryProvider);

      final newReceived = currentReceived + paymentAmount;
      final newStatus = newReceived >= totalAmount ? 'paid' : 'partial';

      final paymentRepo = ref.read(receivablePaymentRepositoryProvider);
      final paymentRes = await CreateReceivablePaymentUsecase(paymentRepo).call(
        ReceivablePaymentEntity(
          id: DateTime.now().millisecondsSinceEpoch,
          transactionId: transactionId,
          customerId: customerId,
          amount: paymentAmount,
          notes: notes,
        ),
      );

      if (paymentRes.isFailure) {
        return Result.failure(error: paymentRes.error ?? 'Payment creation failed');
      }

      final txnRes = await GetTransactionUsecase(transactionRepository).call(
        transactionId,
      );
      if (txnRes.isSuccess && txnRes.data != null) {
        final txn = txnRes.data!;
        await UpateTransactionUsecase(transactionRepository).call(
          txn.copyWith(
            receivedAmount: newReceived,
            paymentStatus: newStatus,
          ),
        );
      }

      if (customerId != null) {
        final customerRepository = ref.read(customerRepositoryProvider);
        final customerRes = await GetCustomerUsecase(customerRepository).call(
          customerId,
        );
        if (customerRes.isSuccess && customerRes.data != null) {
          final customer = customerRes.data!;
          final newOutstanding = (customer.outstandingBalance - paymentAmount).clamp(0, double.maxFinite.toInt());
          await UpdateCustomerUsecase(customerRepository).call(
            customer.copyWith(outstandingBalance: newOutstanding),
          );
        }
      }

      await load(transactionId);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
