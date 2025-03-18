// lib/features/payment/domain/interfaces/payment_gateway.dart
import '../entities/payment_request.dart';
import '../entities/payment_response.dart';
import '../entities/payment_status.dart';

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