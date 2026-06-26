import 'package:flutter/material.dart';

import '../../app/routes/app_routes.dart';
import '../../core/themes/app_sizes.dart';
import '../../domain/entities/product_entity.dart';
import '../../generated/app_localizations.dart';
import 'app_dialog.dart';

class AppLowStockDialog {
  AppLowStockDialog._();

  static Future<void> show(List<ProductEntity> products) async {
    final context = AppRoutes.rootNavigatorKey.currentContext;
    if (context == null) return;

    final l10n = AppLocalizations.of(context)!;

    await AppDialog.show(
      title: l10n.lowStock_title,
      child: _LowStockDialogContent(products: products),
      leftButtonText: l10n.lowStock_ok,
    );
  }
}

class _LowStockDialogContent extends StatelessWidget {
  final List<ProductEntity> products;

  const _LowStockDialogContent({required this.products});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          l10n.lowStock_message(products.length),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.padding),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 250),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: products.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            itemBuilder: (context, index) {
              return _LowStockItem(product: products[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _LowStockItem extends StatelessWidget {
  final ProductEntity product;

  const _LowStockItem({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.padding / 2),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 18, color: Colors.orange.shade700),
          const SizedBox(width: AppSizes.padding / 2),
          Expanded(
            child: Text(
              product.name,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radius / 2),
            ),
            child: Text(
              '${product.stock}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
