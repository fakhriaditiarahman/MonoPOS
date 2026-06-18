import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../generated/app_localizations.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';

class OrderCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final int stock;
  final int price;
  final String priceType;
  final String unit;
  final double initialQuantity;
  final VoidCallback? onTapCard;
  final VoidCallback? onTapRemove;
  final Function(double) onChangedQuantity;
  final List<String>? availableUnits;
  final String? selectedUnit;
  final ValueChanged<String?>? onChangedUnit;

  const OrderCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.stock,
    required this.price,
    this.priceType = 'retail',
    this.unit = 'pcs',
    this.initialQuantity = 0,
    this.onTapCard,
    this.onTapRemove,
    required this.onChangedQuantity,
    this.availableUnits,
    this.selectedUnit,
    this.onChangedUnit,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  late double quantity;
  final quantityController = TextEditingController();

  @override
  void initState() {
    quantity = widget.initialQuantity == 0 ? 1 : widget.initialQuantity;
    quantityController.text = _formatQty(quantity);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    if (widget.initialQuantity != oldWidget.initialQuantity) {
      quantity = widget.initialQuantity == 0 ? 1 : widget.initialQuantity;
      quantityController.text = _formatQty(quantity);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  String _formatQty(double val) {
    return val == val.roundToDouble() ? val.toInt().toString() : val.toStringAsFixed(1);
  }

  void _updateQuantity(double val) {
    if (val < 0) val = 0;
    quantity = val;
    quantityController.text = _formatQty(val);
    setState(() {});
    widget.onChangedQuantity(val);
  }

  @override
  Widget build(BuildContext context) {
    final showUnitPicker = (widget.availableUnits?.length ?? 0) >= 1;
    final hasMultipleUnits = (widget.availableUnits?.length ?? 0) > 1;

    return Material(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: InkWell(
        onTap: widget.onTapCard,
        child: Ink(
          padding: const EdgeInsets.all(AppSizes.padding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.surfaceContainer,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: widget.priceType == 'grosir'
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                widget.priceType == 'grosir'
                                    ? AppLocalizations.of(context)!.home_grosir
                                    : AppLocalizations.of(context)!.home_retail,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              CurrencyFormatter.format(widget.price),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/${widget.selectedUnit ?? widget.unit}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.cart_stock(widget.stock)} ${widget.selectedUnit ?? widget.unit}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                        const SizedBox(height: 6),
                        if (showUnitPicker)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Builder(
                              builder: (ctx) {
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await showDialog<String>(
                                      context: ctx,
                                      builder: (dialogCtx) => SimpleDialog(
                                        title: const Text('Pilih Satuan'),
                                        children: widget.availableUnits!.map((u) {
                                          return SimpleDialogOption(
                                            onPressed: () => Navigator.pop(dialogCtx, u),
                                            child: Text(u),
                                          );
                                        }).toList(),
                                      ),
                                    );
                                    if (result != null) {
                                      widget.onChangedUnit?.call(result);
                                    }
                                  },
                                  child: Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.surfaceContainer,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.selectedUnit ?? widget.unit,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (hasMultipleUnits) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        Container(
                          height: 36,
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Row(
                            children: [
                              AppButton(
                                width: 30,
                                height: 30,
                                padding: EdgeInsets.zero,
                                buttonColor: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  '-',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  _updateQuantity(quantity - (hasMultipleUnits ? 0.5 : 1));
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: SizedBox(
                                  height: 30,
                                  child: TextField(
                                    controller: quantityController,
                                    textAlign: TextAlign.center,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                                    ],
                                    style: Theme.of(context).textTheme.bodySmall,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.surfaceContainer,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).colorScheme.surfaceContainer,
                                        ),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val);
                                      if (parsed != null && parsed != quantity) {
                                        quantity = parsed;
                                        setState(() {});
                                        widget.onChangedQuantity(parsed);
                                      }
                                    },
                                    onSubmitted: (val) {
                                      _updateQuantity(double.tryParse(val) ?? quantity);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              AppButton(
                                width: 30,
                                height: 30,
                                padding: EdgeInsets.zero,
                                buttonColor: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                child: Text(
                                  '+',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  _updateQuantity(quantity + (hasMultipleUnits ? 0.5 : 1));
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            CurrencyFormatter.format((widget.price * quantity).round()),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppImage(
                    width: 70,
                    height: 70,
                    image: widget.imageUrl,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(width: 0.5, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                    errorWidget: Icon(
                      Icons.image,
                      color: Theme.of(context).colorScheme.surfaceDim,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.onTapRemove != null)
                    AppButton(
                      text: AppLocalizations.of(context)!.cart_remove,
                      width: 70,
                      fontSize: 10,
                      borderRadius: BorderRadius.circular(4),
                      padding: const EdgeInsets.all(AppSizes.padding / 4),
                      buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.32),
                      textColor: Theme.of(context).colorScheme.error,
                      onTap: () {
                        AppDialog.show(
                          title: AppLocalizations.of(context)!.cart_confirm,
                          text: AppLocalizations.of(context)!.cart_removeProductConfirm,
                          rightButtonText: AppLocalizations.of(context)!.cart_remove,
                          leftButtonText: AppLocalizations.of(context)!.home_cancel,
                          onTapRightButton: (context) {
                            widget.onTapRemove!();
                            context.pop();
                          },
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
