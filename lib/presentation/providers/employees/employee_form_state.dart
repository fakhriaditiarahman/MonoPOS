class EmployeeFormState {
  final String? username;
  final String? name;
  final String? password;
  final String role;
  final bool isLoaded;

  const EmployeeFormState({
    this.username,
    this.name,
    this.password,
    this.role = 'kasir',
    this.isLoaded = false,
  });

  bool get isFormValid =>
      (username?.isNotEmpty ?? false) &&
      (name?.isNotEmpty ?? false) &&
      (password?.isNotEmpty ?? false) &&
      (password?.length ?? 0) >= 6;

  bool get hasChanges =>
      (username?.isNotEmpty ?? false) || (name?.isNotEmpty ?? false) || (password?.isNotEmpty ?? false);

  EmployeeFormState copyWith({
    String? username,
    String? name,
    String? password,
    String? role,
    bool? isLoaded,
  }) {
    return EmployeeFormState(
      username: username ?? this.username,
      name: name ?? this.name,
      password: password ?? this.password,
      role: role ?? this.role,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}
