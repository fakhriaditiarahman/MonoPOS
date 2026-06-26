import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../providers/piutang/piutang_notifier.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../../widgets/app_snack_bar.dart';
import '../../../widgets/app_text_field.dart';

class PiutangScreen extends ConsumerStatefulWidget {
  const PiutangScreen({super.key});

  @override
  ConsumerState<PiutangScreen> createState() => _PiutangScreenState();
}

class _PiutangScreenState extends ConsumerState<PiutangScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(piutangNotifierProvider.notifier).loadCreditTransactions();
    });
  }

  void _showPaymentDialog(TransactionEntity txn) {
    final sisa = txn.totalAmount - txn.receivedAmount;
    final amountController = TextEditingController();

    AppDialog.show(
      title: 'Bayar Cicilan',
      text:
          'Transaksi: ${txn.id}\n'
          'Pelanggan: ${txn.customerName ?? '-'}\n'
          'Total: ${CurrencyFormatter.format(txn.totalAmount)}\n'
          'Dibayar: ${CurrencyFormatter.format(txn.receivedAmount)}\n'
          'Sisa: ${CurrencyFormatter.format(sisa)}',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSizes.padding),
        child: AppTextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          controller: amountController,
          labelText: 'Jumlah Bayar',
          hintText: 'Masukkan jumlah...',
        ),
      ),
      rightButtonText: 'Bayar',
      leftButtonText: 'Batal',
      onTapRightButton: (ctx) async {
        final amount = int.tryParse(amountController.text);
        if (amount == null || amount <= 0) {
          AppSnackBar.showError('Masukkan jumlah yang valid');
          return;
        }
        if (amount > sisa) {
          AppSnackBar.showError('Jumlah melebihi sisa piutang');
          return;
        }

        ctx.pop();

        var res = await AppDialog.showProgress(() {
          return ref
              .read(piutangNotifierProvider.notifier)
              .payInstallment(
                transactionId: txn.id!,
                totalAmount: txn.totalAmount,
                currentReceived: txn.receivedAmount,
                customerId: txn.customerId,
                paymentAmount: amount,
                notes: 'Pembayaran cicilan',
              );
        });

        if (res.isSuccess) {
          AppSnackBar.show('Pembayaran berhasil');
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(piutangNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Piutang'),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          ListView.separated(
            key: const PageStorageKey<String>('piutang_list'),
            padding: const EdgeInsets.all(AppSizes.padding),
            itemCount: state.transactions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final txn = state.transactions[i];
              final isPending = txn.paymentStatus == 'pending';
              final isPartial = txn.paymentStatus == 'partial';
              final sisa = txn.totalAmount - txn.receivedAmount;

              return ListTile(
                title: Text(
                  txn.customerName ?? 'ID: ${txn.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.format(txn.totalAmount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (txn.dueDate != null)
                      Text(
                        'Jatuh tempo: ${DateTimeFormatter.normal(txn.dueDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    if (isPartial)
                      Text(
                        'Sisa: ${CurrencyFormatter.format(sisa)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!txn.paymentStatus.contains('paid'))
                      AppButton(
                        text: 'Bayar',
                        height: 28,
                        fontSize: 10,
                        borderRadius: BorderRadius.circular(4),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        buttonColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        onTap: () => _showPaymentDialog(txn),
                      ),
                    if (!txn.paymentStatus.contains('paid')) const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.orange.shade100
                            : isPartial
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isPending
                            ? 'Belum Lunas'
                            : isPartial
                            ? 'Angsuran'
                            : 'Lunas',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPending
                              ? Colors.orange.shade800
                              : isPartial
                              ? Colors.blue.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () => context.push('/account/piutang/piutang-detail/${txn.id}'),
              );
            },
          ),
          if (state.isLoading) const AppProgressIndicator(),
          if (!state.isLoading && state.transactions.isEmpty)
            AppEmptyState(
              title: 'Belum ada piutang',
              subtitle: 'Transaksi kredit akan muncul di sini',
            ),
        ],
      ),
    );
  }
}
