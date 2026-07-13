import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../generated/app_localizations.dart';
import '../../../providers/home/home_notifier.dart';
import '../../../widgets/app_empty_state.dart';
import 'order_card.dart';

class CartPanelBody extends StatelessWidget {
  final PanelController panelController;
  final bool isPanelUsed;

  const CartPanelBody({super.key, required this.panelController, this.isPanelUsed = true});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 62),
      physics: const NeverScrollableScrollPhysics(),
      child: _OrderList(panelController: panelController, isPanelUsed: isPanelUsed),
    );
  }
}

class _OrderList extends ConsumerWidget {
  final PanelController panelController;
  final bool isPanelUsed;

  const _OrderList({required this.panelController, this.isPanelUsed = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    if (homeState.orderedProducts.isEmpty) {
      return SizedBox(
        height: AppSizes.screenHeight(context) - 272,
        child: AppEmptyState(
          title: AppLocalizations.of(context)!.cart_empty,
          subtitle: AppLocalizations.of(context)!.cart_noProducts,
        ),
      );
    }

    return SizedBox(
      height: AppSizes.screenHeight(context) - 272,
      child: Scrollbar(
        child: ListView.builder(
          itemCount: homeState.orderedProducts.length,
          padding: const EdgeInsets.all(AppSizes.padding),
          itemBuilder: (context, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.padding),
              child: OrderCard(
                name: homeState.orderedProducts[i].name,
                imageUrl: homeState.orderedProducts[i].imageUrl,
                stock: homeState.orderedProducts[i].stock,
                price: homeState.orderedProducts[i].price,
                priceType: homeState.orderedProducts[i].priceType,
                unit: homeState.orderedProducts[i].unit,
                initialQuantity: homeState.orderedProducts[i].quantity,
                onChangedQuantity: (val) {
                  ref.read(homeNotifierProvider.notifier).onChangedOrderedProductQuantity(i, val);
                },
                onTapRemove: () {
                  final isLast = homeState.orderedProducts.length == 1;
                  ref.read(homeNotifierProvider.notifier).onRemoveOrderedProduct(homeState.orderedProducts[i]);
                  if (isLast && isPanelUsed) panelController.close();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
