// lib/features/messaging/data/templates/twilio_templates.dart
import '../../domain/entities/sms_template.dart';

/// Pre-approved Twilio business templates for WhatsApp
class TwilioTemplates {
  static final Map<String, SmsTemplate> templates = {
    'verification_code': SmsTemplate(
      id: 'verification_code',
      providerId: 'twilio',
      content:
          '{{1}} is your verification code. For your security, do not share this code.',
      placeholders: ['{{1}}'],
      description: 'Send a verification code',
    ),
    'appointment_reminder': SmsTemplate(
      id: 'appointment_reminder',
      providerId: 'twilio',
      content:
          'Reminder: Your appointment is scheduled for {{1}}. Please reply YES to confirm or NO to reschedule.',
      placeholders: ['{{1}}'],
      description: 'Remind patient of upcoming appointment',
    ),
    'prescription_ready': SmsTemplate(
      id: 'prescription_ready',
      providerId: 'twilio',
      content:
          'Your prescription for {{1}} is ready for pickup at {{2}}. Please bring your ID.',
      placeholders: ['{{1}}', '{{2}}'],
      description: 'Notify patient that prescription is ready',
    ),
    'test_results': SmsTemplate(
      id: 'test_results',
      providerId: 'twilio',
      content:
          'Your test results are now available. Please {{1}} to discuss them with your doctor.',
      placeholders: ['{{1}}'],
      description: 'Notify patient about test results',
    ),
  };

  /// Get all available templates
  static List<SmsTemplate> getAll() => templates.values.toList();

  /// Get a template by ID
  static SmsTemplate? getById(String id) => templates[id];
}
