import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../generated/app_localizations.dart';
import '../../../providers/home/home_notifier.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialog.dart';

class _PriceTypeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final isGrosir = homeState.selectedPriceType == 'grosir';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: AppLocalizations.of(context)!.home_retail,
            isSelected: !isGrosir,
            onTap: () => ref.read(homeNotifierProvider.notifier).onChangedPriceType('retail'),
          ),
          _ToggleButton(
            label: AppLocalizations.of(context)!.home_grosir,
            isSelected: isGrosir,
            onTap: () => ref.read(homeNotifierProvider.notifier).onChangedPriceType('grosir'),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class CartPanelHeader extends ConsumerWidget {
  final PanelController panelController;

  const CartPanelHeader({super.key, required this.panelController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return Container(
      width: AppSizes.screenWidth(context),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.padding,
        AppSizes.padding / 2,
        AppSizes.padding,
        AppSizes.padding / 1.5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Theme.of(context).colorScheme.surfaceContainer,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radius * 2),
          topRight: Radius.circular(AppSizes.radius * 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.padding / 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.cart_products(homeState.orderedProducts.length),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _PriceTypeToggle(),
            ],
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Spacer(),
              AppButton(
                height: 26,
                borderRadius: BorderRadius.circular(4),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
                buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.32),
                enabled: homeState.orderedProducts.isNotEmpty,
                onTap: () {
                  AppDialog.show(
                    title: AppLocalizations.of(context)!.cart_confirm,
                    text: AppLocalizations.of(context)!.cart_removeAllConfirm,
                    rightButtonText: AppLocalizations.of(context)!.cart_remove,
                    leftButtonText: AppLocalizations.of(context)!.home_cancel,
                    onTapRightButton: (context) {
                      ref.read(homeNotifierProvider.notifier).onRemoveAllOrderedProduct();
                      panelController.close();
                      context.pop();
                    },
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.clear_rounded,
                      size: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: AppSizes.padding / 4),
                    Text(
                      AppLocalizations.of(context)!.cart_removeAll,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
