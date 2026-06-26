import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/employees/employee_form_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const EmployeeFormScreen({super.key, this.id});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(employeeFormNotifierProvider.notifier).initEmployeeForm(widget.id);

      final state = ref.read(employeeFormNotifierProvider);
      usernameController.text = state.username ?? '';
      nameController.text = state.name ?? '';
      passwordController.text = state.password ?? '';
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void save() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(employeeFormNotifierProvider.notifier).saveEmployee(widget.id);
    });

    if (!mounted) return;
    if (res.isSuccess) {
      context.pop();
      AppSnackBar.show(widget.id == null ? 'Karyawan berhasil ditambahkan' : 'Karyawan berhasil diperbarui');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(employeeFormNotifierProvider.notifier);
    final isLoaded = ref.watch(employeeFormNotifierProvider.select((s) => s.isLoaded));
    final isFormValid = ref.watch(employeeFormNotifierProvider.select((s) => s.isFormValid));
    final currentRole = ref.watch(employeeFormNotifierProvider.select((s) => s.role));
    final isEdit = widget.id != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Karyawan' : 'Tambah Karyawan'),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                children: [
                  AppTextField(
                    controller: usernameController,
                    labelText: 'Username',
                    hintText: 'contoh: kasir2',
                    enabled: !isEdit,
                    onChanged: notifier.onChangedUsername,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: nameController,
                    labelText: 'Nama Lengkap',
                    hintText: 'contoh: Budi Santoso',
                    onChanged: notifier.onChangedName,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: passwordController,
                    labelText: isEdit ? 'Password Baru (biarkan kosong jika tidak diubah)' : 'Password',
                    hintText: 'minimal 6 karakter',
                    obscureText: true,
                    inputFormatters: [LengthLimitingTextInputFormatter(32)],
                    onChanged: notifier.onChangedPassword,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppDropDown(
                    labelText: 'Role',
                    selectedValue: currentRole,
                    dropdownItems: const [
                      DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (v) {
                      if (v != null) notifier.onChangedRole(v);
                    },
                  ),
                  const SizedBox(height: AppSizes.padding * 2),
                  AppButton(
                    text: isEdit ? 'Perbarui Karyawan' : 'Simpan Karyawan',
                    enabled: isEdit || isFormValid,
                    onTap: save,
                  ),
                ],
              ),
            ),
    );
  }
}
