import 'package:flutter/material.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../domain/entities/daily_revenue_entity.dart';

class RevenueCard extends StatelessWidget {
  final DailyRevenueEntity revenue;

  const RevenueCard({super.key, required this.revenue});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var parsedDate = DateTime.tryParse(revenue.date);
    var formattedDate = parsedDate != null ? DateTimeFormatter.detailed(parsedDate.toIso8601String()) : revenue.date;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.padding),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.surfaceContainer),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedDate,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.padding),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.receipt_long_outlined,
                    label: '${revenue.transactionCount} Transaksi',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.padding / 2),
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${revenue.totalProducts} Produk',
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.padding / 2),
              Row(
                children: [
                  Text(
                    'Total: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(revenue.totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
