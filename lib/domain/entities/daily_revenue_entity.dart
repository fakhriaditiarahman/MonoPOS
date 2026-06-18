import 'package:equatable/equatable.dart';

class DailyRevenueEntity extends Equatable {
  final String date;
  final int totalAmount;
  final int transactionCount;
  final int totalProducts;

  const DailyRevenueEntity({
    required this.date,
    required this.totalAmount,
    required this.transactionCount,
    required this.totalProducts,
  });

  @override
  List<Object> get props => [date, totalAmount, transactionCount, totalProducts];
}
