import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../generated/app_localizations.dart';

class ProductsCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final bool enabled;
  final int? displayPrice;
  final String? priceType;

  const ProductsCard({
    super.key,
    required this.product,
    this.onTap,
    this.enabled = true,
    this.displayPrice,
    this.priceType,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashColor: Colors.black.withValues(alpha: 0.06),
        splashFactory: InkRipple.splashFactory,
        highlightColor: Colors.black12,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              width: 0.5,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: AppImage(
                      image: product.imageUrl,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(width: 0.5, color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                      errorWidget: Icon(
                        Icons.image,
                        color: Theme.of(context).colorScheme.surfaceDim,
                        size: 32,
                      ),
                    ),
                  ),
                  product.stock <= 0 ? const _OutOfStock() : const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 8,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AppLocalizations.of(context)!.product_stockSold(product.stock, product.sold ?? 0)} ${product.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
                  ),
                  if (product.units.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        product.units.map((u) => u.unitName).join(', '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 7,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (displayPrice != null && priceType != null)
                Text(
                  priceType == 'grosir'
                      ? AppLocalizations.of(context)!.product_grosirPrice(CurrencyFormatter.format(displayPrice!))
                      : AppLocalizations.of(context)!.product_retailPrice(CurrencyFormatter.format(displayPrice!)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: priceType == 'grosir' ? Theme.of(context).colorScheme.primary : null,
                  ),
                )
              else ...[
                Text(
                  AppLocalizations.of(context)!.product_retailPrice(CurrencyFormatter.format(product.price)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (product.wholesalePrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.product_grosirPrice(CurrencyFormatter.format(product.wholesalePrice!)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OutOfStock extends StatelessWidget {
  const _OutOfStock();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.padding / 4,
            horizontal: AppSizes.padding / 2,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_circle,
                color: Theme.of(context).colorScheme.outline,
                size: 10,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  AppLocalizations.of(context)!.product_outOfStock,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
