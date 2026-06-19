import '../../../domain/entities/transaction_entity.dart';

class QrisPaymentState {
  final TransactionEntity? transaction;
  final String qrCode;
  final String paymentStatus;
  final String? errorMessage;
  final bool isPolling;
  final int elapsedSeconds;
  final bool autoCheckDone;
  final bool isManualChecking;
  final String qrisInvoiceId;
  final String qrisNmid;

  const QrisPaymentState({
    this.transaction,
    this.qrCode = '',
    this.paymentStatus = 'pending',
    this.errorMessage,
    this.isPolling = false,
    this.elapsedSeconds = 0,
    this.autoCheckDone = false,
    this.isManualChecking = false,
    this.qrisInvoiceId = '',
    this.qrisNmid = '',
  });

  QrisPaymentState copyWith({
    TransactionEntity? transaction,
    String? qrCode,
    String? paymentStatus,
    String? errorMessage,
    bool? isPolling,
    int? elapsedSeconds,
    bool? autoCheckDone,
    bool? isManualChecking,
    String? qrisInvoiceId,
    String? qrisNmid,
  }) {
    return QrisPaymentState(
      transaction: transaction ?? this.transaction,
      qrCode: qrCode ?? this.qrCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      errorMessage: errorMessage,
      isPolling: isPolling ?? this.isPolling,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      autoCheckDone: autoCheckDone ?? this.autoCheckDone,
      isManualChecking: isManualChecking ?? this.isManualChecking,
      qrisInvoiceId: qrisInvoiceId ?? this.qrisInvoiceId,
      qrisNmid: qrisNmid ?? this.qrisNmid,
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isFailed => paymentStatus == 'failed';
  bool get isPending => paymentStatus == 'pending';
}
