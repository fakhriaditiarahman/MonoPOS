import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/receivable_payment_entity.dart';
import '../../../domain/usecases/customer_usecases.dart';
import '../../../domain/usecases/params/base_params.dart';
import '../../../domain/usecases/receivable_payment_usecases.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import '../auth/auth_notifier.dart';
import 'piutang_state.dart';

final piutangNotifierProvider = NotifierProvider<PiutangNotifier, PiutangState>(
  PiutangNotifier.new,
);

class PiutangNotifier extends Notifier<PiutangState> {
  @override
  PiutangState build() {
    return const PiutangState(isLoading: true);
  }

  Future<void> loadCreditTransactions() async {
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authNotifierProvider);
      if (!authState.isAuthenticated || authState.user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final userId = authState.user!.id;
      final transactionRepository = ref.read(transactionRepositoryProvider);
      final res = await GetUserTransactionsUsecase(transactionRepository).call(
        BaseParams(
          param: userId,
          orderBy: 'createdAt',
          sortBy: 'DESC',
          limit: 999,
        ),
      );

      if (res.isSuccess && res.data != null) {
        final creditTxns = res.data!.where((t) => t.paymentType == 'credit').toList();
        state = PiutangState(transactions: creditTxns);
      } else {
        state = state.copyWith(isLoading: false);
      }
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

      // Create receivable payment record
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

      if (paymentRes.isFailure) return Result.failure(error: paymentRes.error ?? 'Payment creation failed');

      // Update transaction received amount and payment status
      final txnRes = await GetTransactionUsecase(transactionRepository).call(transactionId);
      if (txnRes.isSuccess && txnRes.data != null) {
        final txn = txnRes.data!;
        await UpateTransactionUsecase(transactionRepository).call(
          txn.copyWith(
            receivedAmount: newReceived,
            paymentStatus: newStatus,
          ),
        );
      }

      // Update customer outstanding balance
      if (customerId != null) {
        final customerRepository = ref.read(customerRepositoryProvider);
        final customerRes = await GetCustomerUsecase(customerRepository).call(customerId);
        if (customerRes.isSuccess && customerRes.data != null) {
          final customer = customerRes.data!;
          final newOutstanding = (customer.outstandingBalance - paymentAmount).clamp(0, double.maxFinite.toInt());
          await UpdateCustomerUsecase(customerRepository).call(
            customer.copyWith(outstandingBalance: newOutstanding),
          );
        }
      }

      // Reload
      await loadCreditTransactions();

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
