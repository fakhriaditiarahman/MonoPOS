import '../../../domain/entities/transaction_entity.dart';

class DokuPaymentState {
  final TransactionEntity? transaction;
  final String qrCode;
  final String paymentStatus;
  final String? errorMessage;
  final bool isPolling;
  final int elapsedSeconds;
  final bool autoCheckDone;
  final bool isManualChecking;
  final String partnerReferenceNo;
  final String referenceNo;

  const DokuPaymentState({
    this.transaction,
    this.qrCode = '',
    this.paymentStatus = 'pending',
    this.errorMessage,
    this.isPolling = false,
    this.elapsedSeconds = 0,
    this.autoCheckDone = false,
    this.isManualChecking = false,
    this.partnerReferenceNo = '',
    this.referenceNo = '',
  });

  DokuPaymentState copyWith({
    TransactionEntity? transaction,
    String? qrCode,
    String? paymentStatus,
    String? errorMessage,
    bool? isPolling,
    int? elapsedSeconds,
    bool? autoCheckDone,
    bool? isManualChecking,
    String? partnerReferenceNo,
    String? referenceNo,
  }) {
    return DokuPaymentState(
      transaction: transaction ?? this.transaction,
      qrCode: qrCode ?? this.qrCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      errorMessage: errorMessage,
      isPolling: isPolling ?? this.isPolling,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      autoCheckDone: autoCheckDone ?? this.autoCheckDone,
      isManualChecking: isManualChecking ?? this.isManualChecking,
      partnerReferenceNo: partnerReferenceNo ?? this.partnerReferenceNo,
      referenceNo: referenceNo ?? this.referenceNo,
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isFailed => paymentStatus == 'failed';
  bool get isPending => paymentStatus == 'pending';
}
