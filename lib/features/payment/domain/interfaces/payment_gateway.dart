// lib/features/payment/domain/interfaces/payment_gateway.dart
/// Abstract interface for payment gateways
abstract class PaymentGateway {
  /// Unique identifier for the payment gateway
  String get gatewayId;
  
  /// Display name of the payment gateway
  String get displayName;
  
  /// Gateway specific icon
  String get iconAsset;
  
  /// Initialize the payment gateway with configuration
  Future<void> initialize(Map<String, dynamic> config);
  
  /// Create a payment session and get redirect URL or widget data
  Future<PaymentResponse> createPayment(PaymentRequest request);
  
  /// Check the status of a payment
  Future<PaymentStatus> checkPaymentStatus(String paymentId);
  
  /// Process a refund for a payment
  Future<bool> processRefund(String paymentId, {double? amount});
  
  /// Validate webhook or callback data
  bool validateCallback(Map<String, dynamic> data);
  
  /// Extract payment details from callback data
  PaymentStatus extractStatusFromCallback(Map<String, dynamic> data);
}

// lib/features/payment/domain/entities/payment_request.dart
class PaymentRequest {
  final String referenceId;
  final double amount;
  final String currency;
  final String customerEmail;
  final String? customerName;
  final String? customerPhone;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String? returnUrl;
  final String? callbackUrl;

  PaymentRequest({
    required this.referenceId,
    required this.amount,
    required this.currency,
    required this.customerEmail,
    this.customerName,
    this.customerPhone,
    this.description,
    this.metadata,
    this.returnUrl,
    this.callbackUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'amount': amount,
      'currency': currency,
      'customerEmail': customerEmail,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'description': description,
      'metadata': metadata,
      'returnUrl': returnUrl,
      'callbackUrl': callbackUrl,
    };
  }
}

// lib/features/payment/domain/entities/payment_response.dart
enum PaymentResponseType { redirect, widget, error }

class PaymentResponse {
  final PaymentResponseType type;
  final String paymentId;
  final String? redirectUrl;
  final Map<String, dynamic>? widgetData;
  final String? errorMessage;

  PaymentResponse.redirect({
    required this.paymentId,
    required this.redirectUrl,
  })  : type = PaymentResponseType.redirect,
        widgetData = null,
        errorMessage = null;

  PaymentResponse.widget({
    required this.paymentId,
    required this.widgetData,
  })  : type = PaymentResponseType.widget,
        redirectUrl = null,
        errorMessage = null;

  PaymentResponse.error({
    required this.errorMessage,
  })  : type = PaymentResponseType.error,
        paymentId = '',
        redirectUrl = null,
        widgetData = null;

  bool get isSuccess => type != PaymentResponseType.error;
}

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