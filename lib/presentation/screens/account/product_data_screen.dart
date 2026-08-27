import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/product_data_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_success_overlay.dart';

class ProductDataScreen extends ConsumerWidget {
  const ProductDataScreen({super.key});

  Future<void> _onExport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(productDataNotifierProvider.notifier);

    await notifier.exportProducts();
    final state = ref.read(productDataNotifierProvider);

    if (!context.mounted) return;

    if (state.exportedCount != null) {
      AppSuccessOverlay.show(l10n.dataProduct_exportSuccess(state.exportedCount!));
    } else if (state.error != null) {
      AppSnackBar.showError(l10n.dataProduct_exportFailed);
    }
    notifier.clearResult();
  }

  Future<void> _onImport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await AppDialog.show(
      title: l10n.dataProduct_importTitle,
      text: l10n.dataProduct_importConfirm,
      leftButtonText: l10n.dataProduct_cancel,
      rightButtonText: l10n.dataProduct_confirm,
      onTapLeftButton: (ctx) => ctx.pop(false),
      onTapRightButton: (ctx) => ctx.pop(true),
    );

    if (confirmed != true) return;

    final notifier = ref.read(productDataNotifierProvider.notifier);
    await notifier.importProducts();
    final state = ref.read(productDataNotifierProvider);

    if (!context.mounted) return;

    if (state.importedCount != null) {
      AppSuccessOverlay.show(l10n.dataProduct_importSuccess(state.importedCount!));
    } else if (state.error == 'no_file') {
      AppSnackBar.showError(l10n.dataProduct_noFile);
    } else if (state.error == 'invalid_file') {
      AppSnackBar.showError(l10n.dataProduct_invalidFile);
    } else if (state.error != null) {
      AppSnackBar.showError(l10n.dataProduct_importFailed);
    }
    notifier.clearResult();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(productDataNotifierProvider);
    final isWide = AppSizes.isTablet(context) || AppSizes.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataProduct_title),
        titleSpacing: 0,
      ),
      body: Center(
        child: Container(
          constraints: isWide ? const BoxConstraints(maxWidth: 600) : null,
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            children: [
              AppButton(
                text: state.isBusy ? l10n.dataProduct_exporting : l10n.dataProduct_export,
                enabled: !state.isBusy,
                onTap: () => _onExport(context, ref),
                child: state.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSizes.padding),
              AppButton(
                text: state.isBusy ? l10n.dataProduct_importing : l10n.dataProduct_import,
                enabled: !state.isBusy,
                onTap: () => _onImport(context, ref),
                child: state.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
