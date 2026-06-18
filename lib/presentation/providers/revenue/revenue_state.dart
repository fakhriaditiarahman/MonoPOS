import '../../../domain/entities/daily_revenue_entity.dart';

class RevenueState {
  final bool isLoading;
  final List<DailyRevenueEntity>? revenues;

  const RevenueState({
    this.isLoading = false,
    this.revenues,
  });

  RevenueState copyWith({
    bool? isLoading,
    List<DailyRevenueEntity>? revenues,
  }) {
    return RevenueState(
      isLoading: isLoading ?? this.isLoading,
      revenues: revenues ?? this.revenues,
    );
  }
}
