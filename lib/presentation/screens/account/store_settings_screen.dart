import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/store_settings_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class StoreSettingsScreen extends ConsumerStatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  ConsumerState<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends ConsumerState<StoreSettingsScreen> {
  late TextEditingController _storeNameController;
  late TextEditingController _storeAddressController;
  late TextEditingController _receiptFooterController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(storeSettingsNotifierProvider);
    _storeNameController = TextEditingController(text: state.storeName);
    _storeAddressController = TextEditingController(text: state.storeAddress);
    _receiptFooterController = TextEditingController(text: state.receiptFooter);

    _storeNameController.addListener(() {
      ref.read(storeSettingsNotifierProvider.notifier).onChangedStoreName(_storeNameController.text);
    });
    _storeAddressController.addListener(() {
      ref.read(storeSettingsNotifierProvider.notifier).onChangedStoreAddress(_storeAddressController.text);
    });
    _receiptFooterController.addListener(() {
      ref.read(storeSettingsNotifierProvider.notifier).onChangedReceiptFooter(_receiptFooterController.text);
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final notifier = ref.read(storeSettingsNotifierProvider.notifier);
    await notifier.save();
    if (mounted) {
      AppSnackBar.show(AppLocalizations.of(context)!.storeSettings_saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeSettingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.storeSettings_title),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _storeNameController,
                    labelText: AppLocalizations.of(context)!.storeSettings_storeNameLabel,
                    hintText: AppLocalizations.of(context)!.storeSettings_storeNameHint,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _storeAddressController,
                    labelText: AppLocalizations.of(context)!.storeSettings_storeAddressLabel,
                    hintText: AppLocalizations.of(context)!.storeSettings_storeAddressHint,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _receiptFooterController,
                    labelText: AppLocalizations.of(context)!.storeSettings_receiptFooterLabel,
                    hintText: AppLocalizations.of(context)!.storeSettings_receiptFooterHint,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  AppButton(
                    text: state.isSaving
                        ? AppLocalizations.of(context)!.storeSettings_saving
                        : AppLocalizations.of(context)!.storeSettings_save,
                    enabled: state.hasChanges && !state.isSaving,
                    onTap: _onSave,
                    child: state.isSaving
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
    );
  }
}
