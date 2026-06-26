import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';

import '../../providers/customer/customer_form_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const CustomerFormScreen({super.key, this.id});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final creditLimitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(customerFormNotifierProvider.notifier).initCustomerForm(widget.id);

      final state = ref.read(customerFormNotifierProvider);
      nameController.text = state.name ?? '';
      phoneController.text = state.phone ?? '';
      creditLimitController.text = state.creditLimit.toString();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    creditLimitController.dispose();
    super.dispose();
  }

  void createCustomer() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(customerFormNotifierProvider.notifier).createCustomer();
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSnackBar.show('Pelanggan berhasil ditambahkan');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void updateCustomer() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(customerFormNotifierProvider.notifier).updateCustomer(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSnackBar.show('Pelanggan berhasil diupdate');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(customerFormNotifierProvider.notifier);
    final isLoaded = ref.watch(customerFormNotifierProvider.select((s) => s.isLoaded));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                children: [
                  AppTextField(
                    controller: nameController,
                    labelText: 'Nama Pelanggan',
                    hintText: 'Masukkan nama pelanggan',
                    onChanged: notifier.onChangedName,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: phoneController,
                    labelText: 'No. Telepon (opsional)',
                    hintText: 'contoh: 0812xxxxxx',
                    keyboardType: TextInputType.phone,
                    onChanged: notifier.onChangedPhone,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppDropDown(
                    labelText: 'Tipe Pelanggan',
                    selectedValue: ref.watch(customerFormNotifierProvider.select((s) => s.type)),
                    dropdownItems: const [
                      DropdownMenuItem(value: 'retail', child: Text('Retail')),
                      DropdownMenuItem(value: 'grosir', child: Text('Grosir')),
                    ],
                    onChanged: (v) {
                      if (v != null) notifier.onChangedType(v);
                    },
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: creditLimitController,
                    labelText: 'Limit Kredit (opsional)',
                    hintText: '0 = tanpa limit',
                    type: AppTextFieldType.currency,
                    onChanged: notifier.onChangedCreditLimit,
                  ),
                  const SizedBox(height: AppSizes.padding * 2),
                  AppButton(
                    text: widget.id == null ? 'Simpan Pelanggan' : 'Update Pelanggan',
                    enabled: ref.watch(
                      customerFormNotifierProvider.select(
                        (s) => (s.name?.isNotEmpty ?? false),
                      ),
                    ),
                    onTap: () {
                      if (widget.id != null) {
                        updateCustomer();
                      } else {
                        createCustomer();
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
