import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/usecases/params/no_param.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../auth/auth_notifier.dart';
import 'employees_state.dart';

final employeesNotifierProvider = NotifierProvider<EmployeesNotifier, EmployeesState>(
  EmployeesNotifier.new,
);

class EmployeesNotifier extends Notifier<EmployeesState> {
  @override
  EmployeesState build() {
    return const EmployeesState();
  }

  Future<void> getAllEmployees() async {
    state = EmployeesState(allEmployees: state.allEmployees, isLoading: true);

    final userRepository = ref.read(userRepositoryProvider);
    var res = await GetAllUsersUsecase(userRepository).call(NoParam());

    if (res.isSuccess) {
      state = EmployeesState(allEmployees: res.data, isLoading: false);
    } else {
      state = EmployeesState(allEmployees: state.allEmployees, isLoading: false);
    }
  }

  Future<Result<void>> deleteEmployee(String userId) async {
    try {
      final userRepository = ref.read(userRepositoryProvider);
      var res = await DeleteUserUsecase(userRepository).call(userId);

      if (res.isSuccess) {
        final currentUser = ref.read(authNotifierProvider).user;
        if (currentUser?.id == userId) {
          ref.read(authNotifierProvider.notifier).signOut();
        }
        getAllEmployees();
      }

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
