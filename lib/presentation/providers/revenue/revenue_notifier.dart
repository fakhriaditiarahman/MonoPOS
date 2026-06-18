import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/entities/daily_revenue_entity.dart';
import '../../../domain/usecases/revenue_usecases.dart';
import '../auth/auth_notifier.dart';
import 'revenue_state.dart';

final revenueNotifierProvider = NotifierProvider<RevenueNotifier, RevenueState>(
  RevenueNotifier.new,
);

class RevenueNotifier extends Notifier<RevenueState> {
  @override
  RevenueState build() => const RevenueState();

  Future<void> loadRevenue({int days = 7}) async {
    state = state.copyWith(isLoading: true);

    var now = DateTime.now();
    var endDate = _formatDate(now);
    var startDate = _formatDate(now.subtract(Duration(days: days - 1)));

    var authState = ref.read(authNotifierProvider);
    var userId = authState.user?.id ?? '';
    if (userId.isEmpty) {
      state = state.copyWith(isLoading: false, revenues: []);
      return;
    }

    var repo = ref.read(transactionRepositoryProvider);
    var res = await GetDailyRevenueUsecase(repo).call(
      GetDailyRevenueParams(
        userId: userId,
        startDate: '$startDate 00:00:00',
        endDate: '$endDate 23:59:59',
      ),
    );

    if (res.isSuccess) {
      var dailyMap = <String, DailyRevenueEntity>{};

      for (var i = 0; i < days; i++) {
        var date = _formatDate(now.subtract(Duration(days: i)));
        dailyMap[date] = DailyRevenueEntity(
          date: date,
          totalAmount: 0,
          transactionCount: 0,
          totalProducts: 0,
        );
      }

      var transactions = res.data;
      if (transactions == null) {
        state = state.copyWith(isLoading: false, revenues: []);
        return;
      }

      for (var tx in transactions) {
        var date = _extractDate(tx.createdAt ?? '');
        if (date.isEmpty) continue;

        var existing = dailyMap[date];
        if (existing == null) continue;

        int quantitySum = 0;
        var orderedProducts = tx.orderedProducts;
        if (orderedProducts != null) {
          for (var op in orderedProducts) {
            quantitySum = quantitySum + op.quantity.toInt();
          }
        }

        var newTotalAmount = existing.totalAmount + tx.totalAmount;
        var newTxCount = existing.transactionCount + 1;
        var newProductCount = existing.totalProducts + quantitySum;

        dailyMap[date] = DailyRevenueEntity(
          date: date,
          totalAmount: newTotalAmount,
          transactionCount: newTxCount,
          totalProducts: newProductCount,
        );
      }

      var sorted = dailyMap.values.toList()..sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(isLoading: false, revenues: sorted);
    } else {
      state = state.copyWith(isLoading: false, revenues: []);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _extractDate(String isoDate) {
    if (isoDate.length >= 10) return isoDate.substring(0, 10);
    return '';
  }
}
