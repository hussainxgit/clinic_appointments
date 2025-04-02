import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConfig {
  // MyFatoorah Configuration
  static const bool testMode = true;

  static String get apiKey =>
      testMode
          ? dotenv.env['MYFATOORAH_API_KEY'] ?? ''
          : dotenv.env['MYFATOORAH_API_KEY'] ?? '';

  static String get baseUrl =>
      dotenv.env['MYFATOORAH_BASE_URL'] ??
      (testMode
          ? 'https://apitest.myfatoorah.com'
          : 'https://api.myfatoorah.com');

  static String get webhookUrl =>
      dotenv.env['MYFATOORAH_WEBHOOK_URL'] ??
      'https://myfatoorahwebhook-45g5y5hrca-uc.a.run.app';

  // Default payment settings
  static const String defaultCurrency = 'KWD';
  static const String language = 'en';

  // Payment amounts (could be moved to a database later)
  static const Map<String, double> serviceAmounts = {
    'consultation': 15.0,
    'followUp': 10.0,
    'procedure': 50.0,
    'test': 25.0,
  };

  // Payment message templates
  static String paymentMessageTemplate({
    required String patientName,
    required String appointmentDate,
    required String amount,
    required String paymentLink,
  }) {
    return '''$patientName, confirm your $appointmentDate booking by paying $amount\n$paymentLink\nEye Clinic''';
  }

  static String paymentConfirmationTemplate({
    required String patientName,
    required String appointmentDate,
    required String amount,
  }) {
    return '''Thank you $patientName! 

Your payment of $amount $defaultCurrency has been confirmed.
Your appointment on $appointmentDate is now confirmed.

We look forward to seeing you!

Eye Clinic Team
''';
  }
}
