// lib/features/messaging/domain/entities/sms_message.dart
class SmsMessage {
  final String to;
  final String from;
  final String body;
  final Map<String, dynamic>? metadata;

  SmsMessage({
    required this.to,
    required this.from,
    required this.body,
    this.metadata,
  });
}