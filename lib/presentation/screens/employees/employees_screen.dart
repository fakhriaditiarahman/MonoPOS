import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/employees/employees_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeesNotifierProvider.notifier).getAllEmployees();
    });
  }

  void deleteEmployee(String id, String name) {
    AppDialog.show(
      title: 'Hapus Karyawan',
      text: 'Yakin ingin menghapus "$name"?',
      leftButtonText: 'Batal',
      rightButtonText: 'Hapus',
      rightButtonColor: Theme.of(context).colorScheme.errorContainer,
      rightButtonTextColor: Theme.of(context).colorScheme.error,
      onTapRightButton: (ctx) async {
        ctx.pop();
        var res = await AppDialog.showProgress(() {
          return ref.read(employeesNotifierProvider.notifier).deleteEmployee(id);
        });

        if (!mounted) return;
        if (res.isSuccess) {
          AppSnackBar.show('Karyawan berhasil dihapus');
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allEmployees = ref.watch(employeesNotifierProvider.select((s) => s.allEmployees));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Karyawan'),
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.padding),
            child: AppButton(
              height: 26,
              borderRadius: BorderRadius.circular(4),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
              buttonColor: Theme.of(context).colorScheme.surfaceContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSizes.padding / 4),
                  Text(
                    'Tambah',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              onTap: () => context.push('/employees/add'),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(employeesNotifierProvider.notifier).getAllEmployees(),
        child: allEmployees == null
            ? const AppProgressIndicator()
            : allEmployees.isEmpty
            ? AppEmptyState(
                subtitle: 'Belum ada karyawan.',
                buttonText: 'Tambah Karyawan',
                onTapButton: () => context.push('/employees/add'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: allEmployees.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final user = allEmployees[i];
                  final isAdmin = user.role?.value == 'admin';

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isAdmin
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Text(
                            (user.name ?? user.id)[0].toUpperCase(),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name ?? user.id,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${user.id}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAdmin ? 'Admin' : 'Kasir',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isAdmin ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          onPressed: () => context.push('/employees/edit/${user.id}'),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => deleteEmployee(user.id, user.name ?? user.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
