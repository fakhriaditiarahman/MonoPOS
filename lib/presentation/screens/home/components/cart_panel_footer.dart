import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/rupiah_input_formatter.dart';
import '../../../../domain/entities/customer_entity.dart';
import '../../../../generated/app_localizations.dart';
import '../../../providers/customer/customer_notifier.dart';
import '../../../providers/home/home_notifier.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_drop_down.dart';
import '../../../widgets/app_text_field.dart';

class CartPanelFooter extends ConsumerWidget {
  final PanelController panelController;
  final bool isPanelUsed;

  const CartPanelFooter({super.key, required this.panelController, this.isPanelUsed = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPanelExpanded = ref.watch(homeNotifierProvider.select((s) => s.isPanelExpanded));

    return Container(
      width: AppSizes.screenWidth(context),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSizes.padding),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _OrderTotalSummary(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.padding, AppSizes.padding / 2, AppSizes.padding, 0),
            child: Row(
              children: [
                AnimatedContainer(
                  width: isPanelExpanded ? AppSizes.screenWidth(context) / 3 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: AppSizes.screenWidth(context) / 3 - AppSizes.padding / 2,
                      child: _BackButton(panelController: panelController, isPanelUsed: isPanelUsed),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _PayButton(panelController: panelController, isPanelUsed: isPanelUsed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends ConsumerWidget {
  final PanelController panelController;
  final bool isPanelUsed;

  const _BackButton({required this.panelController, this.isPanelUsed = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: AppLocalizations.of(context)!.cart_back,
      buttonColor: Theme.of(context).colorScheme.surface,
      borderColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.primary,
      onTap: () {
        if (isPanelUsed) panelController.close();
      },
    );
  }
}

class _PayButton extends ConsumerWidget {
  final PanelController panelController;
  final bool isPanelUsed;

  const _PayButton({required this.panelController, this.isPanelUsed = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final homeNotifier = ref.read(homeNotifierProvider.notifier);

    return AppButton(
      text: !isPanelUsed || homeState.isPanelExpanded
          ? AppLocalizations.of(context)!.home_pay
          : homeState.orderedProducts.isNotEmpty
          ? "${AppLocalizations.of(context)!.cart_products(homeState.orderedProducts.length)} = ${CurrencyFormatter.format(homeNotifier.getTotalAmount())}"
          : AppLocalizations.of(context)!.home_transaction,
      enabled: homeState.orderedProducts.isNotEmpty,
      onTap: () {
        if (isPanelUsed && !homeState.isPanelExpanded) {
          panelController.open();
        } else {
          AppDialog.show(
            child: const _AdditionalInfoDialog(),
            showButtons: false,
          );
        }
      },
    );
  }
}

class _AdditionalInfoDialog extends ConsumerStatefulWidget {
  const _AdditionalInfoDialog();

  @override
  ConsumerState<_AdditionalInfoDialog> createState() => _AdditionalInfoDialogState();
}

class _AdditionalInfoDialogState extends ConsumerState<_AdditionalInfoDialog> {
  final _amountController = TextEditingController();
  final _customerController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<CustomerEntity> _customerSuggestions = [];
  bool _showCustomerDropdown = false;

  @override
  void dispose() {
    _amountController.dispose();
    _customerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onCustomerSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _customerSuggestions = [];
        _showCustomerDropdown = false;
      });
      return;
    }

    final notifier = ref.read(customerNotifierProvider.notifier);
    final results = await notifier.searchCustomers(query);
    if (!mounted) return;
    setState(() {
      _customerSuggestions = results;
      _showCustomerDropdown = results.isNotEmpty;
    });
  }

  void _onCustomerSelected(CustomerEntity customer) {
    final notifier = ref.read(homeNotifierProvider.notifier);
    _customerController.text = customer.name;
    notifier.onChangedCustomerName(customer.name);
    notifier.onChangedCustomerId(customer.id);
    notifier.onChangedPriceType('grosir');
    setState(() {
      _showCustomerDropdown = false;
      _customerSuggestions = [];
    });
  }

  Future<void> onPay({
    required GoRouter router,
    required HomeNotifier homeNotifier,
  }) async {
    var res = await AppDialog.showProgress(() {
      return homeNotifier.createTransaction();
    });

    if (res.isSuccess) {
      router.go('/transactions/transaction-detail/${res.data}');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  Future<void> onPayQris({
    required GoRouter router,
    required HomeNotifier homeNotifier,
  }) async {
    var res = await AppDialog.showProgress(() {
      return homeNotifier.createQrisTransaction();
    });

    if (res.isSuccess) {
      router.go('/payment/qris');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);
    final homeNotifier = ref.read(homeNotifierProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (homeState.selectedPaymentMethod != 'qris') ...[
          AppTextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            controller: _amountController,
            labelText: AppLocalizations.of(context)!.cart_receivedAmount,
            hintText: AppLocalizations.of(context)!.cart_receivedAmountHint,
            prefixWidget: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Rp',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              RupiahInputFormatter(),
            ],
            onChanged: (val) {
              final clean = val.replaceAll('.', '');
              homeNotifier.onChangedReceivedAmount(int.tryParse(clean) ?? 0);
            },
          ),
          const SizedBox(height: AppSizes.padding),
        ],
        if (homeState.selectedPaymentMethod == 'qris')
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.padding),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: AppSizes.padding / 2),
                  const Expanded(
                    child: Text(
                      'QRIS: Pelanggan scan QR setelah pembayaran',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AppDropDown(
          labelText: AppLocalizations.of(context)!.cart_paymentMethod,
          selectedValue: homeState.selectedPaymentMethod,
          dropdownItems: [
            DropdownMenuItem(
              value: 'bank',
              child: Text(AppLocalizations.of(context)!.cart_bank),
            ),
            DropdownMenuItem(
              value: 'cash',
              child: Text(AppLocalizations.of(context)!.cart_cash),
            ),
            const DropdownMenuItem(
              value: 'qris',
              child: Text('QRIS'),
            ),
          ],
          onChanged: (v) {
            homeNotifier.onChangedPaymentMethod(v);
          },
        ),
        const SizedBox(height: AppSizes.padding),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _customerController,
              labelText: AppLocalizations.of(context)!.cart_customerName,
              hintText: 'Cari pelanggan...',
              onChanged: (v) {
                homeNotifier.onChangedCustomerName(v);
                _onCustomerSearchChanged(v);
              },
              suffixWidget: _customerController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _customerController.clear();
                        homeNotifier.onChangedCustomerName('');
                        homeNotifier.onChangedCustomerId(null);
                        homeNotifier.onChangedPriceType('grosir');
                        setState(() {
                          _customerSuggestions = [];
                          _showCustomerDropdown = false;
                        });
                      },
                      child: const Icon(Icons.clear, size: 16),
                    )
                  : null,
            ),
            if (_showCustomerDropdown && _customerSuggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _customerSuggestions.length,
                  itemBuilder: (ctx, i) {
                    final c = _customerSuggestions[i];
                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        title: Text(c.name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text(
                          c.phone ?? '-',
                          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.outline),
                        ),
                        onTap: () => _onCustomerSelected(c),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSizes.padding),
        AppTextField(
          controller: _descriptionController,
          labelText: AppLocalizations.of(context)!.cart_description,
          hintText: AppLocalizations.of(context)!.cart_descriptionHint,
          onChanged: (v) => homeNotifier.onChangedDescription(v),
        ),
        const SizedBox(height: AppSizes.padding * 1.5),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppLocalizations.of(context)!.home_cancel,
                buttonColor: Theme.of(context).colorScheme.surface,
                borderColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.primary,
                onTap: () {
                  context.pop();
                },
              ),
            ),
            const SizedBox(width: AppSizes.padding / 2),
            Expanded(
              flex: 2,
              child: AppButton(
                text: AppLocalizations.of(context)!.home_pay,
                enabled: homeState.selectedPaymentMethod == 'qris'
                    ? true
                    : (int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0) >= homeNotifier.getTotalAmount(),
                onTap: () {
                  final router = ref.read(goRouterProvider);

                  context.pop();
                  if (homeState.selectedPaymentMethod == 'qris') {
                    onPayQris(
                      homeNotifier: homeNotifier,
                      router: router,
                    );
                  } else {
                    onPay(
                      homeNotifier: homeNotifier,
                      router: router,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderTotalSummary extends ConsumerWidget {
  const _OrderTotalSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final total = ref.read(homeNotifierProvider.notifier).getTotalAmount();

    if (homeState.orderedProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.padding, AppSizes.padding, AppSizes.padding, AppSizes.padding / 2),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.surfaceContainer),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Pembayaran Belanja',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            AppLocalizations.of(context)!.cart_products(homeState.orderedProducts.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
