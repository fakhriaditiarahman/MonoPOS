import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/payment/payment_notifier.dart';
import '../../providers/payment/payment_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_progress_indicator.dart';

class DokuPaymentScreen extends ConsumerStatefulWidget {
  const DokuPaymentScreen({super.key});

  @override
  ConsumerState<DokuPaymentScreen> createState() => _DokuPaymentScreenState();
}

class _DokuPaymentScreenState extends ConsumerState<DokuPaymentScreen> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dokuPaymentNotifierProvider);

    if (state.isPaid && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/transactions/transaction-detail/${state.transaction?.id}');
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.home_pay),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(),
          ),
        ),
        body: state.isPolling ? const Center(child: AppProgressIndicator()) : _buildContent(state),
      ),
    );
  }

  Widget _buildContent(DokuPaymentState state) {
    if (state.errorMessage != null && state.qrCode.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.red),
              const SizedBox(height: AppSizes.padding),
              Text(
                'Gagal memproses pembayaran',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.padding / 2),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.padding * 2),
              AppButton(
                text: AppLocalizations.of(context)!.home_cancel,
                onTap: () {
                  ref.read(dokuPaymentNotifierProvider.notifier).reset();
                  context.pop();
                },
              ),
            ],
          ),
        ),
      );
    }

    if (state.paymentStatus == 'failed') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel_outlined, size: 64, color: AppColors.red),
              const SizedBox(height: AppSizes.padding),
              Text(
                'Pembayaran Gagal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.padding / 2),
              Text(
                state.errorMessage ?? 'Terjadi kesalahan',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final minutes = (state.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.elapsedSeconds % 60).toString().padLeft(2, '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.padding),
          Text(
            'Total Pembayaran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Text(
            CurrencyFormatter.format(state.transaction?.totalAmount ?? 0),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding * 2),
          Container(
            width: 260,
            height: 260,
            padding: const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: state.qrCode.isNotEmpty ? _buildQrDisplay(state.qrCode) : const AppProgressIndicator(),
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            'Scan QRIS di atas untuk membayar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding * 2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.padding,
              vertical: AppSizes.padding / 2,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 18),
                const SizedBox(width: AppSizes.padding / 2),
                Text(
                  '$minutes:$seconds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            state.autoCheckDone ? 'Tekan tombol di bawah setelah pelanggan membayar' : 'Menunggu pembayaran...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (state.autoCheckDone) ...[
            const SizedBox(height: AppSizes.padding * 2),
            AppButton(
              text: state.isManualChecking ? 'Memeriksa...' : 'Cek Pembayaran',
              enabled: !state.isManualChecking,
              onTap: () {
                ref.read(dokuPaymentNotifierProvider.notifier).checkPaymentManually();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrDisplay(String qrData) {
    if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
      return Image.network(
        qrData,
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackQrDisplay(qrData: qrData);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const AppProgressIndicator();
        },
      );
    }

    return _FallbackQrDisplay(qrData: qrData);
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembayaran?'),
        content: const Text('Pembayaran Doku QRIS akan dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.home_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(dokuPaymentNotifierProvider.notifier).cancelPolling();
              context.pop();
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}

class _FallbackQrDisplay extends StatelessWidget {
  final String qrData;

  const _FallbackQrDisplay({required this.qrData});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_2, size: 80, color: Colors.black54),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          'QR Code tersedia',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          'QR sudah terkirim ke printer',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black45,
          ),
        ),
      ],
    );
  }
}
