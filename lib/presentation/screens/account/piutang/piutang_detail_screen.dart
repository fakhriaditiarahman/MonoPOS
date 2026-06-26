import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../domain/entities/receivable_payment_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../providers/piutang/piutang_detail_notifier.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_progress_indicator.dart';
import '../../../widgets/app_snack_bar.dart';
import '../../../widgets/app_text_field.dart';

class PiutangDetailScreen extends ConsumerStatefulWidget {
  final int id;

  const PiutangDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PiutangDetailScreen> createState() => _PiutangDetailScreenState();
}

class _PiutangDetailScreenState extends ConsumerState<PiutangDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(piutangDetailNotifierProvider.notifier).load(widget.id);
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
              .read(piutangDetailNotifierProvider.notifier)
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
    final state = ref.watch(piutangDetailNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Piutang'),
        titleSpacing: 0,
      ),
      body: state.isLoading
          ? const AppProgressIndicator()
          : state.transaction == null
          ? const AppEmptyState(
              title: 'Transaksi tidak ditemukan',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                children: [
                  _TransactionInfoCard(transaction: state.transaction!),
                  const SizedBox(height: AppSizes.padding),
                  _PaymentHistoryCard(payments: state.payments),
                  const SizedBox(height: AppSizes.padding),
                  if (!state.transaction!.paymentStatus.contains('paid'))
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Bayar Cicilan',
                        onTap: () => _showPaymentDialog(state.transaction!),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _TransactionInfoCard extends StatelessWidget {
  final TransactionEntity transaction;

  const _TransactionInfoCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPending = transaction.paymentStatus == 'pending';
    final isPartial = transaction.paymentStatus == 'partial';
    final sisa = transaction.totalAmount - transaction.receivedAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informasi Transaksi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    fontSize: 11,
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
          const SizedBox(height: AppSizes.padding),
          _InfoRow(label: 'ID Transaksi', value: '${transaction.id ?? '-'}'),
          _InfoRow(label: 'Pelanggan', value: transaction.customerName ?? '-'),
          if (transaction.dueDate != null)
            _InfoRow(
              label: 'Jatuh Tempo',
              value: DateTimeFormatter.normal(transaction.dueDate!),
            ),
          _InfoRow(
            label: 'Tgl Transaksi',
            value: DateTimeFormatter.normalWithClock(transaction.createdAt ?? ''),
          ),
          const Divider(height: AppSizes.padding),
          _InfoRow(
            label: 'Total',
            value: CurrencyFormatter.format(transaction.totalAmount),
            valueBold: true,
          ),
          _InfoRow(
            label: 'Sudah Dibayar',
            value: CurrencyFormatter.format(transaction.receivedAmount),
          ),
          if (sisa > 0)
            _InfoRow(
              label: 'Sisa',
              value: CurrencyFormatter.format(sisa),
              valueColor: Theme.of(context).colorScheme.error,
              valueBold: true,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: valueBold ? FontWeight.bold : null,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final List<ReceivablePaymentEntity> payments;

  const _PaymentHistoryCard({required this.payments});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Pembayaran',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          if (payments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
                child: Text(
                  'Belum ada pembayaran',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            ...payments.map((payment) => _PaymentItem(payment: payment)),
        ],
      ),
    );
  }
}

class _PaymentItem extends StatelessWidget {
  final ReceivablePaymentEntity payment;

  const _PaymentItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.padding / 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: Colors.green.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSizes.padding / 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(payment.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (payment.createdAt != null)
                  Text(
                    DateTimeFormatter.normalWithClock(payment.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  Text(
                    payment.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
