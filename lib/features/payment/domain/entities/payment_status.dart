// lib/features/payment/domain/entities/payment_status.dart
enum PaymentStatusType {
  pending,
  processing,
  successful,
  failed,
  refunded,
  partiallyRefunded,
  unknown
}

class PaymentStatus {
  final PaymentStatusType status;
  final String paymentId;
  final String? transactionId;
  final double? amount;
  final String? currency;
  final DateTime? timestamp;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? gatewayResponse;

  PaymentStatus({
    required this.status,
    required this.paymentId,
    this.transactionId,
    this.amount,
    this.currency,
    this.timestamp,
    this.errorCode,
    this.errorMessage,
    this.gatewayResponse,
  });

  bool get isSuccessful => status == PaymentStatusType.successful;
  bool get isPending => 
      status == PaymentStatusType.pending || 
      status == PaymentStatusType.processing;
  bool get isRefunded => 
      status == PaymentStatusType.refunded || 
      status == PaymentStatusType.partiallyRefunded;
}