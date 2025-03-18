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