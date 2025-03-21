// lib/features/messaging/domain/entities/sms_template.dart
class SmsTemplate {
  final String id;
  final String content;
  final List<String> placeholders;
  final String? description;
  final String providerId;

  SmsTemplate({
    required this.id,
    required this.content,
    required this.placeholders,
    required this.providerId,
    this.description,
  });

  /// Replace placeholders with actual values
  String format(List<String> values) {
    if (values.length != placeholders.length) {
      throw Exception('Expected ${placeholders.length} values but got ${values.length}');
    }
    
    String result = content;
    for (int i = 0; i < placeholders.length; i++) {
      result = result.replaceAll(placeholders[i], values[i]);
    }
    
    return result;
  }
}

