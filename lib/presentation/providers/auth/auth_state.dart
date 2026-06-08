import '../../../domain/entities/user_entity.dart';

class AuthState {
  final bool isChecking;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({this.isChecking = false, this.user, this.errorMessage});

  bool get isAuthenticated => user != null;

  AuthState copyWith({bool? isChecking, UserEntity? user, String? errorMessage}) {
    return AuthState(
      isChecking: isChecking ?? this.isChecking,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}
