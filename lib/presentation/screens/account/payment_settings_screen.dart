import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/account/payment_settings_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  late TextEditingController _apiKeyController;
  late TextEditingController _merchantIdController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(paymentSettingsNotifierProvider);
    _apiKeyController = TextEditingController(text: state.apiKey);
    _merchantIdController = TextEditingController(text: state.merchantId);

    _apiKeyController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedApiKey(_apiKeyController.text);
    });
    _merchantIdController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedMerchantId(_merchantIdController.text);
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _merchantIdController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);
    await notifier.save();
    if (mounted) {
      AppSuccessOverlay.show('Pengaturan KlikQRIS tersimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentSettingsNotifierProvider);
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan KlikQRIS'),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(text: 'Koneksi KlikQRIS'),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(
                    controller: _apiKeyController,
                    labelText: 'API Key',
                    hintText: 'x-api-key dari dashboard KlikQRIS',
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _merchantIdController,
                    labelText: 'ID Merchant',
                    hintText: 'ID Merchant dari dashboard KlikQRIS',
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _SandboxToggle(
                    value: state.isSandbox,
                    onChanged: notifier.onChangedIsSandbox,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _InfoBox(
                    apiKey: state.apiKey,
                    merchantId: state.merchantId,
                    isSandbox: state.isSandbox,
                  ),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  AppButton(
                    text: state.isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SandboxToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SandboxToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sandbox Mode',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Menggunakan environment sandbox KlikQRIS' : 'Menggunakan environment production KlikQRIS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String apiKey;
  final String merchantId;
  final bool isSandbox;

  const _InfoBox({
    required this.apiKey,
    required this.merchantId,
    required this.isSandbox,
  });

  @override
  Widget build(BuildContext context) {
    final isConfigured = apiKey.isNotEmpty && merchantId.isNotEmpty;

    if (isConfigured) {
      final modeText = isSandbox ? 'Sandbox' : 'Production';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: AppSizes.padding / 2),
            Expanded(
              child: Text(
                'KlikQRIS dikonfigurasi. Mode $modeText akan digunakan.',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.outline, size: 20),
          const SizedBox(width: AppSizes.padding / 2),
          const Expanded(
            child: Text(
              'Mode Mock: QRIS akan menggunakan simulasi tanpa koneksi ke KlikQRIS. '
              'Isi API Key dan ID Merchant untuk mengaktifkan mode KlikQRIS langsung.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
