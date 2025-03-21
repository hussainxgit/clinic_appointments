// lib/features/messaging/domain/interfaces/sms_provider.dart
import '../entities/sms_message.dart';
import '../entities/sms_response.dart';

/// Abstract interface for SMS providers like Twilio, MessageBird, etc.
abstract class SmsProvider {
  /// Provider identifier
  String get providerId;
  
  /// Display name of the provider
  String get displayName;
  
  /// Initialize the provider with configuration
  Future<void> initialize(Map<String, dynamic> config);
  
  /// Send an SMS message
  Future<SmsResponse> sendSms(SmsMessage message);
  
  /// Check status of a sent message
  Future<SmsResponse> checkStatus(String messageId);
  
  /// Validate webhook data from the provider
  bool validateWebhook(Map<String, dynamic> data);
  
  /// Extract SMS delivery status from webhook data
  SmsDeliveryStatus extractStatusFromWebhook(Map<String, dynamic> data);
}