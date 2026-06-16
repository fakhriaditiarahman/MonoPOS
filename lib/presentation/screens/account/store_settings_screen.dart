import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/store_settings_notifier.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_text_field.dart';

class StoreSettingsScreen extends ConsumerWidget {
  const StoreSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeSettingsNotifierProvider);
    final notifier = ref.read(storeSettingsNotifierProvider.notifier);

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
                  _StoreNameField(
                    initialValue: state.storeName,
                    onChanged: notifier.onChangedStoreName,
                  ),
                  _StoreAddressField(
                    initialValue: state.storeAddress,
                    onChanged: notifier.onChangedStoreAddress,
                  ),
                  _ReceiptFooterField(
                    initialValue: state.receiptFooter,
                    onChanged: notifier.onChangedReceiptFooter,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StoreNameField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _StoreNameField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.storeSettings_storeNameLabel,
        hintText: AppLocalizations.of(context)!.storeSettings_storeNameHint,
        onChanged: onChanged,
      ),
    );
  }
}

class _StoreAddressField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _StoreAddressField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.storeSettings_storeAddressLabel,
        hintText: AppLocalizations.of(context)!.storeSettings_storeAddressHint,
        maxLines: 3,
        onChanged: onChanged,
      ),
    );
  }
}

class _ReceiptFooterField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ReceiptFooterField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.storeSettings_receiptFooterLabel,
        hintText: AppLocalizations.of(context)!.storeSettings_receiptFooterHint,
        maxLines: 3,
        onChanged: onChanged,
      ),
    );
  }
}
