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
        title: const Text('Payment Gateway (Midtrans)'),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(text: 'Koneksi Midtrans'),
                  const SizedBox(height: AppSizes.padding / 2),
                  _ServerKeyField(
                    initialValue: state.serverKey,
                    onChanged: notifier.onChangedServerKey,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _ClientKeyField(
                    initialValue: state.clientKey,
                    onChanged: notifier.onChangedClientKey,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _MerchantNameField(
                    initialValue: state.merchantName,
                    onChanged: notifier.onChangedMerchantName,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _EnvironmentToggle(
                    isProduction: state.isProduction,
                    onChanged: notifier.onChangedIsProduction,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  _InfoBox(
                    isConfigured: state.serverKey.isNotEmpty,
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

class _ServerKeyField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ServerKeyField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Server Key',
      hintText: 'Isi dengan Server Key Midtrans',
      obscureText: true,
      onChanged: onChanged,
    );
  }
}

class _ClientKeyField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _ClientKeyField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Client Key',
      hintText: 'Isi dengan Client Key Midtrans',
      onChanged: onChanged,
    );
  }
}

class _MerchantNameField extends ConsumerWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _MerchantNameField({required this.initialValue, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: initialValue);

    return AppTextField(
      controller: controller,
      labelText: 'Nama Merchant',
      hintText: 'Nama merchant untuk ditampilkan di QR',
      onChanged: onChanged,
    );
  }
}

class _EnvironmentToggle extends StatelessWidget {
  final bool isProduction;
  final ValueChanged<bool> onChanged;

  const _EnvironmentToggle({required this.isProduction, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Environment',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isProduction ? 'Production' : 'Sandbox',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isProduction ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          Switch(
            value: isProduction,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final bool isConfigured;
  const _InfoBox({required this.isConfigured});

  @override
  Widget build(BuildContext context) {
    if (isConfigured) {
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
            const Expanded(
              child: Text(
                'Midtrans sudah dikonfigurasi. Mode QRIS real akan digunakan.',
                style: TextStyle(fontSize: 12),
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
              'Mode Mock: QRIS akan menggunakan simulasi tanpa koneksi ke Midtrans. '
              'Isi Server Key di atas untuk mengaktifkan mode real.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
