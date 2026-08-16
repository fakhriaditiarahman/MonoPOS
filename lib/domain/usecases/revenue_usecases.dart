import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetDailyRevenueUsecase extends Usecase<Result, GetDailyRevenueParams> {
  GetDailyRevenueUsecase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  @override
  Future<Result<List<TransactionEntity>>> call(GetDailyRevenueParams params) async {
    return _transactionRepository.getTransactionsByDateRange(
      params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      paymentStatus: params.paymentStatus,
      showAllUsers: params.showAllUsers,
    );
  }
}

class GetDailyRevenueParams {
  final String userId;
  final String startDate;
  final String endDate;
  final String? paymentStatus;
  final bool showAllUsers;

  const GetDailyRevenueParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
    this.paymentStatus,
    this.showAllUsers = false,
  });
}
