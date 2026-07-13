import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/account/payment_settings_notifier.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_text_field.dart';

class PaymentSettingsScreen extends ConsumerWidget {
  const PaymentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentSettingsNotifierProvider);
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Doku'),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(text: 'Koneksi Doku SNAP QRIS'),
                  const SizedBox(height: AppSizes.padding / 2),
                  _ClientIdField(
                    initialValue: state.clientId,
                    onChanged: notifier.onChangedClientId,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _ClientSecretField(
                    initialValue: state.clientSecret,
                    onChanged: notifier.onChangedClientSecret,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _MerchantIdField(
                    initialValue: state.merchantId,
                    onChanged: notifier.onChangedMerchantId,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _TerminalIdField(
                    initialValue: state.terminalId,
                    onChanged: notifier.onChangedTerminalId,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _SandboxToggle(
                    value: state.isSandbox,
                    onChanged: notifier.onChangedIsSandbox,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _PrivateKeyField(
                    initialValue: state.privateKey,
                    onChanged: notifier.onChangedPrivateKey,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _InfoBox(
                    clientId: state.clientId,
                    clientSecret: state.clientSecret,
                    merchantId: state.merchantId,
                    isSandbox: state.isSandbox,
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

class _ClientIdField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ClientIdField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Client ID',
      hintText: 'X-PARTNER-ID dari Doku Dashboard',
      obscureText: true,
      onChanged: onChanged,
    );
  }
}

class _ClientSecretField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ClientSecretField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Client Secret',
      hintText: 'Secret Key dari Doku Dashboard',
      obscureText: true,
      onChanged: onChanged,
    );
  }
}

class _MerchantIdField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _MerchantIdField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Merchant ID',
      hintText: 'Merchant ID dari Doku',
      onChanged: onChanged,
    );
  }
}

class _TerminalIdField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _TerminalIdField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Terminal ID',
      hintText: 'ID terminal (contoh: POS-001)',
      onChanged: onChanged,
    );
  }
}

class _SandboxToggle extends ConsumerWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SandboxToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class _PrivateKeyField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _PrivateKeyField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'RSA Private Key',
      hintText: 'Masukkan RSA private key (format PEM)',
      obscureText: true,
      minLines: 4,
      maxLines: 6,
      onChanged: onChanged,
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
