// lib/features/messaging/domain/entities/sms_response.dart
enum SmsDeliveryStatus {
  sent,
  delivered,
  failed,
  undelivered,
  queued,
  unknown
}

class SmsResponse {
  final bool success;
  final String? messageId;
  final String? errorMessage;
  final SmsDeliveryStatus status;
  final Map<String, dynamic>? providerResponse;

  SmsResponse._({
    required this.success,
    this.messageId,
    this.errorMessage,
    this.status = SmsDeliveryStatus.unknown,
    this.providerResponse,
  });

  factory SmsResponse.success({
    required String messageId,
    SmsDeliveryStatus status = SmsDeliveryStatus.sent,
    Map<String, dynamic>? providerResponse,
  }) {
    return SmsResponse._(
      success: true,
      messageId: messageId,
      status: status,
      providerResponse: providerResponse,
    );
  }

  factory SmsResponse.error({
    required String errorMessage,
    SmsDeliveryStatus status = SmsDeliveryStatus.failed,
    Map<String, dynamic>? providerResponse,
  }) {
    return SmsResponse._(
      success: false,
      errorMessage: errorMessage,
      status: status,
      providerResponse: providerResponse,
    );
  }
}