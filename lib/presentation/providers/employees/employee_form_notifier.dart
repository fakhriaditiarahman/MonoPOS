import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/user_usecases.dart';
import 'employee_form_state.dart';
import 'employees_notifier.dart';

final employeeFormNotifierProvider = NotifierProvider.autoDispose<EmployeeFormNotifier, EmployeeFormState>(
  EmployeeFormNotifier.new,
);

class EmployeeFormNotifier extends AutoDisposeNotifier<EmployeeFormState> {
  String? _originalPassword;

  @override
  EmployeeFormState build() {
    return const EmployeeFormState();
  }

  Future<void> initEmployeeForm(String? userId) async {
    if (userId == null) {
      state = state.copyWith(isLoaded: true);
      return;
    }

    final userRepository = ref.read(userRepositoryProvider);
    var res = await GetUserUsecase(userRepository).call(userId);

    if (res.isSuccess && res.data != null) {
      var user = res.data!;
      _originalPassword = user.password;
      state = state.copyWith(
        username: user.id,
        name: user.name,
        password: user.password,
        role: user.role?.value ?? 'kasir',
        isLoaded: true,
      );
    } else {
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<Result<dynamic>> saveEmployee(String? userId) async {
    try {
      final userRepository = ref.read(userRepositoryProvider);

      var password = state.password;
      if (userId != null && (password == null || password.isEmpty)) {
        password = _originalPassword;
      }

      var user = UserEntity(
        id: state.username!,
        name: state.name,
        password: password,
        role: UserRole.fromValue(state.role),
        authProvider: AuthProvider.local,
      );

      if (userId != null) {
        var res = await UpateUserUsecase(userRepository).call(user);
        ref.read(employeesNotifierProvider.notifier).getAllEmployees();
        return res;
      } else {
        var res = await CreateUserUsecase(userRepository).call(user);
        ref.read(employeesNotifierProvider.notifier).getAllEmployees();
        return res;
      }
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  void onChangedUsername(String value) {
    state = state.copyWith(username: value);
  }

  void onChangedName(String value) {
    state = state.copyWith(name: value);
  }

  void onChangedPassword(String value) {
    state = state.copyWith(password: value);
  }

  void onChangedRole(String value) {
    state = state.copyWith(role: value);
  }
}
