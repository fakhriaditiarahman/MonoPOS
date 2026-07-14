import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/account/payment_settings_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  late TextEditingController _merchantIdController;
  late TextEditingController _terminalIdController;
  late TextEditingController _privateKeyController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(paymentSettingsNotifierProvider);
    _clientIdController = TextEditingController(text: state.clientId);
    _clientSecretController = TextEditingController(text: state.clientSecret);
    _merchantIdController = TextEditingController(text: state.merchantId);
    _terminalIdController = TextEditingController(text: state.terminalId);
    _privateKeyController = TextEditingController(text: state.privateKey);

    _clientIdController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedClientId(_clientIdController.text);
    });
    _clientSecretController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedClientSecret(_clientSecretController.text);
    });
    _merchantIdController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedMerchantId(_merchantIdController.text);
    });
    _terminalIdController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedTerminalId(_terminalIdController.text);
    });
    _privateKeyController.addListener(() {
      ref.read(paymentSettingsNotifierProvider.notifier).onChangedPrivateKey(_privateKeyController.text);
    });
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _merchantIdController.dispose();
    _terminalIdController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);
    await notifier.save();
    if (mounted) {
      AppSnackBar.show('Pengaturan Doku tersimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentSettingsNotifierProvider);
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Doku'),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(text: 'Koneksi Doku SNAP QRIS'),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(
                    controller: _clientIdController,
                    labelText: 'Client ID',
                    hintText: 'X-PARTNER-ID dari Doku Dashboard',
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _clientSecretController,
                    labelText: 'Client Secret',
                    hintText: 'Secret Key dari Doku Dashboard',
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _merchantIdController,
                    labelText: 'Merchant ID',
                    hintText: 'Merchant ID dari Doku',
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _terminalIdController,
                    labelText: 'Terminal ID',
                    hintText: 'ID terminal (contoh: POS-001)',
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _SandboxToggle(
                    value: state.isSandbox,
                    onChanged: notifier.onChangedIsSandbox,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _privateKeyController,
                    labelText: 'RSA Private Key',
                    hintText: 'Masukkan RSA private key (format PEM)',
                    obscureText: true,
                    minLines: 4,
                    maxLines: 6,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _InfoBox(
                    clientId: state.clientId,
                    clientSecret: state.clientSecret,
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
                  value ? 'Menggunakan environment sandbox Doku' : 'Menggunakan environment production Doku',
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
  final String clientId;
  final String clientSecret;
  final String merchantId;
  final bool isSandbox;

  const _InfoBox({
    required this.clientId,
    required this.clientSecret,
    required this.merchantId,
    required this.isSandbox,
  });

  @override
  Widget build(BuildContext context) {
    final isConfigured = clientId.isNotEmpty && clientSecret.isNotEmpty && merchantId.isNotEmpty;

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
                'Doku SNAP QRIS dikonfigurasi. Mode $modeText akan digunakan.',
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
              'Mode Mock: QRIS akan menggunakan simulasi tanpa koneksi ke Doku. '
              'Isi Client ID, Client Secret, dan Merchant ID untuk mengaktifkan mode Doku langsung.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
