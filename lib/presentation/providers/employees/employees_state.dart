import '../../../domain/entities/user_entity.dart';

class EmployeesState {
  final List<UserEntity>? allEmployees;
  final bool isLoading;

  const EmployeesState({this.allEmployees, this.isLoading = false});
}
